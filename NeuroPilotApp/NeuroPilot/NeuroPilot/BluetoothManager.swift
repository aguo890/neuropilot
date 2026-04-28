import Foundation
import CoreBluetooth
import Combine

/// A Bluetooth-based telemetry provider for NeuroPilot.
/// Scans for and connects to BLE-enabled neural telemetry hardware.
class BluetoothManager: NSObject, ObservableObject, TelemetryProvider, CBCentralManagerDelegate, CBPeripheralDelegate {
    @Published var status: ConnectionStatus = .disconnected
    @Published var packetsPerSecond: Int = 0
    
    private var packetCount = 0
    private var timer: Timer?
    
    private var centralManager: CBCentralManager!
    private var targetPeripheral: CBPeripheral?
    
    private var isManualDisconnect = false
    
    /// NeuroPilot Specific UUIDs (Standard BCI Profile Placeholders)
    private let serviceUUID = CBUUID(string: "BD420000-0000-4000-8000-000000000000")
    private let characteristicUUID = CBUUID(string: "BD420001-0000-4000-8000-000000000000")
    
    var onPacketReceived: ((SpikePacket) -> Void)?
    
    override init() {
        super.init()
        // Initialize central manager on a background queue to keep UI responsive
        centralManager = CBCentralManager(delegate: self, queue: DispatchQueue(label: "com.neuropilot.bluetooth"))
    }
    
    // MARK: - TelemetryProvider Protocol
    
    func connect() {
        isManualDisconnect = false
        guard centralManager.state == .poweredOn else {
            DispatchQueue.main.async {
                self.status = .error("Bluetooth is \(self.centralManager.state == .poweredOff ? "Off" : "Unavailable")")
            }
            return
        }
        
        DispatchQueue.main.async {
            self.status = .connecting
        }
        
        // Scan for the NeuroPilot service
        centralManager.scanForPeripherals(withServices: [serviceUUID], options: [CBCentralManagerScanOptionAllowDuplicatesKey: false])
        startMetricsTimer()
    }
    
    func disconnect() {
        isManualDisconnect = true
        if let peripheral = targetPeripheral {
            centralManager.cancelPeripheralConnection(peripheral)
        }
        centralManager.stopScan()
        stopMetricsTimer()
        DispatchQueue.main.async {
            self.status = .disconnected
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
    
    private func stopMetricsTimer() {
        timer?.invalidate()
        timer = nil
        DispatchQueue.main.async {
            self.packetsPerSecond = 0
        }
        packetCount = 0
    }
    
    // MARK: - CBCentralManagerDelegate
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state != .poweredOn {
            DispatchQueue.main.async {
                self.status = .error("Bluetooth State: \(central.state)")
            }
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        // For MVP, we auto-connect to the first peripheral offering our service
        targetPeripheral = peripheral
        targetPeripheral?.delegate = self
        centralManager.stopScan()
        centralManager.connect(peripheral, options: nil)
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        DispatchQueue.main.async {
            self.status = .connected
        }
        peripheral.discoverServices([serviceUUID])
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        DispatchQueue.main.async {
            self.status = .error(error?.localizedDescription ?? "Connection failed")
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        if !isManualDisconnect {
            DispatchQueue.main.async {
                self.status = .connecting
            }
            // Resume scanning to find the device again
            centralManager.scanForPeripherals(withServices: [serviceUUID], options: [CBCentralManagerScanOptionAllowDuplicatesKey: false])
        } else {
            DispatchQueue.main.async {
                self.status = .disconnected
            }
            targetPeripheral = nil
        }
    }
    
    // MARK: - CBPeripheralDelegate
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else { return }
        for service in services where service.uuid == serviceUUID {
            peripheral.discoverCharacteristics([characteristicUUID], for: service)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let characteristics = service.characteristics else { return }
        for characteristic in characteristics where characteristic.uuid == characteristicUUID {
            // Subscribe to notifications for neural data
            peripheral.setNotifyValue(true, for: characteristic)
        }
    }
    
    private var buffer = Data()
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard let data = characteristic.value else { return }
        
        // BLE data often arrives in fragments (MTU size usually ~185 bytes)
        // Accumulate in buffer and process newline-delimited JSON
        processIncomingData(data)
    }
    
    private func processIncomingData(_ data: Data) {
        buffer.append(data)
        
        while let newlineIndex = buffer.firstIndex(of: 10) { // 10 is '\n'
            let packetData = buffer.subdata(in: 0..<newlineIndex)
            buffer.removeSubrange(0...newlineIndex)
            
            if let packet = try? JSONDecoder().decode(SpikePacket.self, from: packetData) {
                DispatchQueue.main.async {
                    self.packetCount += 1
                    self.onPacketReceived?(packet)
                }
            }
        }
    }
}
