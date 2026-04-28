import Foundation
import Network

protocol TelemetryClientDelegate: AnyObject {
    func telemetryClient(_ client: TelemetryClient, didReceive packet: SpikePacket)
    func telemetryClient(_ client: TelemetryClient, didChangeState isConnected: Bool)
}

class TelemetryClient {
    private var connection: NWConnection?
    private let queue = DispatchQueue(label: "com.neuropilot.telemetry")
    private let decoder = JSONDecoder()
    
    weak var delegate: TelemetryClientDelegate?
    
    // Store incomplete data if packets are split across reads
    private var buffer = Data()
    
    func connect(host: String = "127.0.0.1", port: UInt16 = 9000) {
        let endpoint = NWEndpoint.hostPort(host: NWEndpoint.Host(host), port: NWEndpoint.Port(rawValue: port)!)
        
        let parameters = NWParameters.tcp
        connection = NWConnection(to: endpoint, using: parameters)
        
        connection?.stateUpdateHandler = { [weak self] state in
            guard let self = self else { return }
            switch state {
            case .ready:
                print("TelemetryClient connected to \(host):\(port)")
                self.delegate?.telemetryClient(self, didChangeState: true)
                self.receiveLoop()
            case .failed(let error):
                print("TelemetryClient connection failed: \(error)")
                self.delegate?.telemetryClient(self, didChangeState: false)
                self.disconnect()
            case .cancelled:
                print("TelemetryClient connection cancelled")
                self.delegate?.telemetryClient(self, didChangeState: false)
            default:
                break
            }
        }
        
        connection?.start(queue: queue)
    }
    
    func disconnect() {
        connection?.cancel()
        connection = nil
    }
    
    private func receiveLoop() {
        connection?.receive(minimumIncompleteLength: 1, maximumLength: 65536) { [weak self] data, context, isComplete, error in
            guard let self = self else { return }
            
            if let data = data, !data.isEmpty {
                self.buffer.append(data)
                self.processBuffer()
            }
            
            if let error = error {
                print("TelemetryClient receive error: \(error)")
                self.delegate?.telemetryClient(self, didChangeState: false)
                self.disconnect()
                return
            }
            
            if isComplete {
                print("TelemetryClient connection closed by remote host")
                self.delegate?.telemetryClient(self, didChangeState: false)
                self.disconnect()
                return
            }
            
            self.receiveLoop()
        }
    }
    
    private func processBuffer() {
        // Find newline characters to split JSON lines
        guard let newlineData = "\n".data(using: .utf8) else { return }
        
        while let range = buffer.range(of: newlineData) {
            let lineData = buffer.subdata(in: 0..<range.lowerBound)
            buffer.removeSubrange(0..<range.upperBound)
            
            if !lineData.isEmpty {
                do {
                    let packet = try decoder.decode(SpikePacket.self, from: lineData)
                    delegate?.telemetryClient(self, didReceive: packet)
                } catch {
                    print("TelemetryClient JSON decode error: \(error)")
                }
            }
        }
    }
}
