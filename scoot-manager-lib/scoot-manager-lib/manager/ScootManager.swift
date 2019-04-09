//
//  ScootManager.swift
//  scoot-manager
//
//  Created by UZU on 4/9/19.
//  Copyright © 2019 Ammar Tinwala. All rights reserved.
//

import Foundation
import RxBluetoothKit
import RxSwift
import CoreBluetooth

class ScootManager {
    private static var privateShared : ScootManager?
    
    class func shared() -> ScootManager { // change class to final to prevent override
        guard let uwShared = privateShared else {
            privateShared = ScootManager()
            return privateShared!
        }
        return uwShared
    }
    
    class func destroy() {
        privateShared = nil
    }
    
    private var listener : ScootListener? = nil
    private var scooterBleName: String = ""
    public var isConnected: Bool = false
    
    var scannedPeripheral: ScannedPeripheral?
    var peripheral: Peripheral?
    var peripheralCharacteristicRx: Characteristic?
    var peripheralCharacteristicTx: Characteristic?
    var disposable: Disposable?
    var checkDisposable: Disposable?
    var lastResponse: [UInt8]?
    let centralManager = CentralManager(queue: .main)
    
    private var checkLock = false
    private var checkCruise = false
    private var checkLight = false
    
    var isLocked = true
    var isCruised = true
    var isLighted = true
    
    var distance = 0.0
    var battery = 100
    var speed = 0.0
    
    public func setListener(l: ScootListener){
        listener = l
    }
    
    public func triggerConnection(targetBleName: String){
        
        
        var isConnecting = false
        
        centralManager.observeState()
            .startWith(centralManager.state)
            .filter { $0 == .poweredOn }
            .flatMap { _ in self.centralManager.scanForPeripherals(withServices: [BLE_SERVICE_UUID], options: nil) }
            .filter({ $0.advertisementData.isConnectable ?? false })
            .subscribe(onNext: { (scannedPeripheral) in
                if(isConnecting) {
                    return
                }
                
                self.scannedPeripheral = scannedPeripheral
                let scannedDeviceName = self.scannedPeripheral?.advertisementData.localName
                if (scannedDeviceName == targetBleName) {
                    print("SUCCESS")
                    print("스캔디바이스 : \(String(describing: scannedDeviceName))")
                    self.scooterBleName = scannedDeviceName ?? ""
                    isConnecting = true
                    
                    // connect
                    self.connectToDevice(scannedPeripheral: self.scannedPeripheral)
                }
                
            }, onError: { (error) in
                print(error)
            })
    }
    
    private func connectToDevice(scannedPeripheral: ScannedPeripheral?){
        print("Establishing Connection")
        // subscrive connection status
        _ = scannedPeripheral?.peripheral
            .observeConnection()
            .subscribe({ (event) in
                print("isConnected: \(event.element!)")
                self.isConnected = event.element!
                if(self.isConnected){
                    self.listener?.onConnected()
                }else{
                    self.listener?.onDisconnected()
                }
            })
        
        self.disposable = self.scannedPeripheral?.peripheral.establishConnection()
            .flatMap({ $0.discoverServices([BLE_SERVICE_UUID]) }).asObservable()
            .flatMap({ Observable.from($0) })
            .flatMap({ $0.discoverCharacteristics([BLE_CHARACTERISTIC_UUID_RX, BLE_CHARACTERISTIC_UUID_TX])}).asObservable()
            .flatMap({ Observable.from($0) })
            .subscribe(onNext: { (characteristic) in
                
                //region Logs
                let uuidDevice = characteristic.uuid.uuidString + "/\(self.scooterBleName)"
                
                print("\(BLE_CHARACTERISTIC_UUID_STRING_TX + "/\(self.scooterBleName)" )")
                
                if (uuidDevice == BLE_CHARACTERISTIC_UUID_STRING_TX + "/\(self.scooterBleName)") {
                    print("Setting tx characteristic")
                    self.peripheralCharacteristicTx = characteristic
                }
                
                print("\(BLE_CHARACTERISTIC_UUID_STRING_RX + "/\(self.scooterBleName)")")
                // endregion

                if (uuidDevice == BLE_CHARACTERISTIC_UUID_STRING_RX + "/\(self.scooterBleName)") {
                    print("Setting rx characteristic")
                    self.peripheralCharacteristicRx = characteristic
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 5.0, execute:
                        {
                            self.check()
                            self.sendCheckCommands()
                            self.read()
                            self.startTimer()
                            self.unlock()
                            self.sendCommand(.cruiseOn)
                            UserDefaults.standard.set(true, forKey: "connectBLE")
                        }
                    )
                }
            }, onError: { (error) in
                print("Error Device: \(error)")
                self.onConnectionFailed()
                self.listener?.onError(e: error.localizedDescription)
            }
        )
    }
    
    
    private func onConnected(connectedPeripheral: ScannedPeripheral?){
        lastConnectedDeviceName = connectedPeripheral?.advertisementData.localName
        listener?.onConnected()
    }
    
    
    private func onConnectionFailed() { //연결실패
        listener?.onConnectionFailed()
    }
    
    private func onDisposed(){
        listener?.onDisposed()
    }
    
    func triggerDisconnect() {
        print("triggerDisconnect")
        disposable?.dispose()
        checkDisposable?.dispose()
    }
    
    func triggerDispose(){
        if(isConnected){
            triggerDisconnect()
        }
    }
    
    func triggerReconnect(){
        let reconnectTo = lastConnectedDeviceName
        if (reconnectTo == nil) {
            onConnectionFailed()
            return
        }
        triggerConnection(targetBleName: reconnectTo!)
    }
    
    
    
    let preferences = UserDefaults.standard
    let lastConnectedDeviceNameKey = "lastConnectedDeviceNameKey"

    var lastConnectedDeviceName: String? {
        get {
            if preferences.object(forKey: lastConnectedDeviceNameKey) == nil {
                return nil
            } else {
                return preferences.string(forKey: lastConnectedDeviceNameKey)
            }
        }
        set {
            preferences.set(newValue, forKey: lastConnectedDeviceNameKey)
            preferences.synchronize()
        }
    }
    
    
    public func triggerCommand(_ command: Command){
        sendCommand(command)
    }
    // =========
    
    
    private func sendCommand(_ command: Command) {
        print("Sending command \(command.val())...")//3
        
        let data = Data(bytes: commands[command]!)
        
        //        print("명령어확인 : \(String(describing: self.peripheralCharacteristicTx))")
        
        let d = self.peripheralCharacteristicTx?.writeValue(data, type: .withResponse)
            
            .subscribe(onSuccess: { (characteristic) in
                print("커맨드 성공command sent success...\(characteristic)")
            }, onError: { (error) in
                print("command sent failed...")
                print("Error received: \(error)")
            })
        d?.dispose()
    }
    
    private func sendCheckCommands() {
        sendCommand(.checkLock)
        sendCommand(.checkCruise)
        sendCommand(.checkLights)
    }
    
    
    // region timer
    weak var timer: Timer?

    private func startTimer() {
        timer?.invalidate() // just in case you had existing `Timer`, `invalidate` it before we lose our reference to it
        timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            // do something here
            self?.getSpeed()
            self?.getDistance()
            self?.getBattery()
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
    }
    // endregion
    
    
    // if appropriate, make sure to stop your timer in `deinit`
    deinit {
        stopTimer()
    }
    
    private func getSpeed() {
        sendCommand(.speed)
    }
    
    private func getDistance() {
        sendCommand(.distance)
    }
    
    private func getBattery() {
        sendCommand(.battery)
    }
    
    public func read() {
        let _ = peripheralCharacteristicRx?
            .observeValueUpdateAndSetNotification()
            .subscribe(onNext: { (characteristic) in
                let data = characteristic.value
                self.updateUI(data)
                print("리드 : \(String(describing: data))")
            }, onError: { (error) in
                print("Error in reading: \(error)")
            })
    }
    
    public func check() {
        checkDisposable = peripheralCharacteristicRx?
            .observeValueUpdateAndSetNotification()
            .subscribe(onNext: {
                let data = $0.value
                self.updateUIForCheck(data)
            }, onError: { (error) in
                print("Error in reading: \(error)")
            })
    }
    
    public func lock() {
        print("유저디폴트 : \(String(describing: UserDefaults.standard.bool(forKey: "connectBLE")))")
        
        if UserDefaults.standard.bool(forKey: "connectBLE") {
            sendCommand(.lockOff)
            UserDefaults.standard.removeObject(forKey: "connectBLE")
            UserDefaults.standard.removeObject(forKey: "ScootDeviceName")
                    } else {
            listener?.onError(e: "Scooter Failed to Lock")
        }
    }
    
    private func unlock() {
        if UserDefaults.standard.bool(forKey: "connectBLE") == false {
            sendCommand(.lockOn)
            print("풀림")
        } else {
            listener?.onError(e: "Scooter Failed to UnLock")
        }
    }
    
    // TODO Rename
    func updateUIForCheck(_ data: Data?) {
        
        if (data == nil) {
            return
        }
        
        let bytes: [UInt8] = [UInt8](data!)
        if (bytes.count < 5) { //super request returns a third empty message
            return;
        }
        
        let requestBit: UInt8 = bytes[5]
        print("Request Bit: \(requestBit)")
        
        if (bytes.count <= 10) {
            if (!checkLock && requestBit == 0xb2) {
                checkLock = true
                self.isLocked = bytes[6] == 0x02
            }
            if (!checkCruise && requestBit == 0x7c) {
                checkCruise = true
                self.isCruised = bytes[6] == 0x01
            }
            if (!checkLight && requestBit == 0x7d) {
                checkLight = true
                self.isLighted = bytes[6] == 0x02
            }
            
            if (checkLock && checkCruise && checkLight) {
                checkDisposable?.dispose()
            }
        }
    }
    
    // TODO Rename
    func updateUI(_ data: Data?) {
        
        if (data == nil) {
            return
        }
        
        let bytes: [UInt8] = [UInt8](data!)
        if (bytes.count < 5) { //super request returns a third empty message
            return;
        }
        
        let requestBit: UInt8 = bytes[5]
        print("Request Bit: \(requestBit)")
        
        if (bytes.count > 10) { //Super handling
            if (requestBit == 0xb0) {
                lastResponse = bytes
                return
            } else if (requestBit == 0x31) {
                let temp = bytes[9] + bytes[8]
                let life: Int = Int.init(String(temp, radix: 16, uppercase: false), radix: 16)!
                self.battery = life
            } else {
                if (lastResponse != nil) {
                    var combinedResponse: [UInt8] = lastResponse! + bytes
                    var temp:String = String(format: "%02X", combinedResponse[17]) + String(format: "%02X", combinedResponse[16])
                    //                    print("Speed hex: \(temp)")
                    let speed: Int16 = Int16(truncatingIfNeeded: Int(temp, radix: 16)!)
                    let v: Double = Double(speed) / 1000
                    self.speed = v
                    
                    temp = String(format: "%02X", combinedResponse[25]) + String(format: "%02X", combinedResponse[24])
                    //                    print("Distance hex: \(temp)")
                    let distance: Int16 = Int16(truncatingIfNeeded: Int(temp, radix: 16)!)
                    let dist: Double = Double(distance) / 100
                    self.distance = dist
                }
            }
        } else {
            
            if (!checkLock && requestBit == 0xb2) {
                checkLock = true
                isLocked = bytes[6] == 0x02
            }
            
            if (!checkCruise && requestBit == 0x7c) {
                checkCruise = true
                isCruised = bytes[6] == 0x01
            }
            
            if (!checkLight && requestBit == 0x7d) {
                checkLight = true
                isLighted = bytes[6] == 0x02
            }
        }
    }
    
    func round(toRound: Double, decimals:Double) -> Double {
        let temp = Int(toRound * pow(10.0, decimals))
        let temp2 = Double(temp)
        return temp2 / pow(10.0, decimals)
    }
    
}
