import Foundation
import Network
import Combine

class TCPTelemetryClient: ObservableObject, TelemetryProvider {
    @Published var status: ConnectionStatus = .disconnected
    @Published var packetsPerSecond: Int = 0
    
    private var connection: NWConnection?
    private let queue = DispatchQueue(label: "com.neuropilot.telemetry")
    
    private var packetCount = 0
    private var timer: Timer?
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
        timer?.invalidate()
        timer = nil
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
    private var pendingPackets: [SpikePacket] = []
    private var lastBatchDispatchTime: Date = .distantPast
    private let batchInterval: TimeInterval = 0.016 // 60Hz update rate
    
    private func processIncomingData(_ data: Data) {
        buffer.append(data)
        
        // Split by newline
        while let newlineIndex = buffer.firstIndex(of: 10) { // 10 is '\n'
            let packetData = buffer.subdata(in: 0..<newlineIndex)
            buffer.removeSubrange(0...newlineIndex)
            
            if let packet = try? JSONDecoder().decode(SpikePacket.self, from: packetData) {
                pendingPackets.append(packet)
            }
        }
        
        // Batch dispatch to main thread to avoid overwhelming UI (throttle to ~60Hz)
        let now = Date()
        if !pendingPackets.isEmpty && now.timeIntervalSince(lastBatchDispatchTime) >= batchInterval {
            let packets = pendingPackets
            pendingPackets.removeAll()
            lastBatchDispatchTime = now
            
            DispatchQueue.main.async {
                self.packetCount += packets.count
                self.onPacketsReceived?(packets)
            }
        }
    }
    
    private func startMetricsTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            DispatchQueue.main.async {
                self?.packetsPerSecond = self?.packetCount ?? 0
                self?.packetCount = 0
            }
        }
    }
}
