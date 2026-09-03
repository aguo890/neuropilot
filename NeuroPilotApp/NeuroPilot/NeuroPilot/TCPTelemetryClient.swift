import Foundation
import Network
import Combine

class TCPTelemetryClient: ObservableObject, TelemetryProvider {
    @Published var status: ConnectionStatus = .disconnected
    @Published var packetsPerSecond: Int = 0
    
    private var connection: NWConnection?
    private let queue = DispatchQueue(label: "com.neuropilot.telemetry")
    
    private var packetCount = 0
    private var metricsTimer: Timer?
    private var reconnectTimer: Timer?
    
    // Default connection parameters
    private let host: String
    private let port: Int
    
    // Tracking connection intent
    private var isManualDisconnect = false
    
    // Callback for received packets
    var onPacketsReceived: (([SpikePacket]) -> Void)?
    
    init(host: String = "127.0.0.1", port: Int = 9000) {
        self.host = host
        self.port = port
    }
    
    func connect() {
        isManualDisconnect = false
        reconnectTimer?.invalidate()
        reconnectTimer = nil
        
        guard status == .disconnected || status == .connecting else { return }
        
        let nwHost = NWEndpoint.Host(host)
        let nwPort = NWEndpoint.Port(integerLiteral: UInt16(port))
        
        connection = NWConnection(host: nwHost, port: nwPort, using: .tcp)
        status = .connecting
        
        connection?.stateUpdateHandler = { [weak self] state in
            DispatchQueue.main.async {
                switch state {
                case .ready:
                    self?.status = .connected
                    self?.startReceiving()
                    self?.startFlushTimer()
                    self?.startMetricsTimer()
                case .failed(let error):
                    self?.status = .error(error.localizedDescription)
                    self?.initiateReconnect()
                case .cancelled:
                    if self?.isManualDisconnect == false {
                        self?.initiateReconnect()
                    } else {
                        self?.status = .disconnected
                    }
                    self?.stop()
                default:
                    break
                }
            }
        }
        
        connection?.start(queue: queue)
    }
    
    func disconnect() {
        isManualDisconnect = true
        reconnectTimer?.invalidate()
        reconnectTimer = nil
        connection?.cancel()
        status = .disconnected
        stop()
    }
    
    private func initiateReconnect() {
        guard !isManualDisconnect else { return }
        
        stop()
        status = .connecting
        
        // Wait 2 seconds before attempting to reconnect to avoid spamming
        reconnectTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { [weak self] _ in
            self?.connect()
        }
    }
    
    private func stop() {
        flushTimer?.cancel()
        flushTimer = nil
        metricsTimer?.invalidate()
        metricsTimer = nil
        packetCount = 0
        DispatchQueue.main.async {
            self.packetsPerSecond = 0
        }
    }
    
    private func startReceiving() {
        receiveNextMessage()
    }
    
    private func receiveNextMessage() {
        connection?.receive(minimumIncompleteLength: 1, maximumLength: 65536) { [weak self] data, context, isComplete, error in
            if let data = data, !data.isEmpty {
                self?.processIncomingData(data)
            }
            
            if error == nil && !isComplete {
                self?.receiveNextMessage()
            }
        }
    }
    
    private var buffer = Data()
    
    // Pending packet queue is only touched on `queue` (receive callback thread).
    // The flush timer dispatches a snapshot to the main thread at a fixed 60 Hz cadence,
    // completely independent of when TCP data arrives. This prevents burst buffering
    // where dozens of packets would accumulate and arrive all at once causing cursor stutter.
    private var pendingPackets: [SpikePacket] = []
    private var flushTimer: DispatchSourceTimer?
    
    private func processIncomingData(_ data: Data) {
        // All processing stays on `queue` — no time-gating here
        buffer.append(data)
        
        while let newlineIndex = buffer.firstIndex(of: 10) { // 10 is '\n'
            let packetData = buffer.subdata(in: 0..<newlineIndex)
            buffer.removeSubrange(0...newlineIndex)
            
            if let packet = try? JSONDecoder().decode(SpikePacket.self, from: packetData) {
                pendingPackets.append(packet)
            }
        }
    }
    
    /// Starts a 60 Hz DispatchSourceTimer that flushes the pending packet queue to the main
    /// thread on a steady clock tick. This decouples UI updates from TCP burst arrival timing,
    /// eliminating the cursor buffering / catch-up stutter.
    private func startFlushTimer() {
        let source = DispatchSource.makeTimerSource(queue: queue)
        // Fire every 16.67ms (60 Hz), leeway of 1ms to allow coalescing
        source.schedule(deadline: .now(), repeating: .milliseconds(16), leeway: .milliseconds(1))
        source.setEventHandler { [weak self] in
            guard let self, !self.pendingPackets.isEmpty else { return }
            let packets = self.pendingPackets
            self.pendingPackets.removeAll(keepingCapacity: true)
            DispatchQueue.main.async {
                self.packetCount += packets.count
                self.onPacketsReceived?(packets)
            }
        }
        source.resume()
        flushTimer = source
    }
    
    private func startMetricsTimer() {
        metricsTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            DispatchQueue.main.async {
                self?.packetsPerSecond = self?.packetCount ?? 0
                self?.packetCount = 0
            }
        }
    }
}
