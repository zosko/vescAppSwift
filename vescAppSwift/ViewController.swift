//
//  ViewController.swift
//  vescAppSwift
//
//  Created by Bosko Petreski on 15.7.22.
//

import UIKit
import CoreBluetooth

class ViewController: UIViewController, CBCentralManagerDelegate, CBPeripheralDelegate, UITableViewDelegate, UITableViewDataSource {
    
    //MARK: Variables
    var centralManager: CBCentralManager!
    var connectedPeripheral: CBPeripheral!
    var peripherals : [CBPeripheral] = []
    var txCharacteristic: CBCharacteristic!
    var txWriteType : CBCharacteristicWriteType = .withoutResponse
    var arrPedalessData : [[String:String]] = []
    var timerValues : Timer!
    var vescController : VESC!
    var password = "Calibike"
    
    //MARK: IBOutlets
    @IBOutlet var tblPedalessData : UITableView!
    
    //MARK: IBActions
    @IBAction func onBtnChangePassword() {
        let alert = UIAlertController(title: "Change password", message: "", preferredStyle: .alert)
        let actionSave = UIAlertAction(title: "Save", style: .default) { action in
            guard let newPass = alert.textFields?.first?.text else { return }
            self.password = newPass
            
//            vescController.terminal(cmd: "sp \(newPass)").forEach { chunk in
//                self.connectedPeripheral.writeValue(chunk, for: self.txCharacteristic, type: self.txWriteType)
//            }
        }
        alert.addAction(actionSave)
        let actionCancel = UIAlertAction(title: "Cancel", style: .destructive) { action in }
        alert.addAction(actionCancel)
        alert.addTextField { textField in
            textField.text = self.password
        }
        self.present(alert, animated: true, completion: nil)
    }
    @IBAction func onBtnConnect(){
        if connectedPeripheral != nil {
            centralManager.cancelPeripheralConnection(connectedPeripheral)
            timerValues.invalidate()
            timerValues = nil
            connectedPeripheral = nil;
            peripherals.removeAll()
        }
        else{
            peripherals.removeAll()
            centralManager.scanForPeripherals(withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey:false])
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                self.stopSearchReader()
            }
        }
    }
    
    @IBAction func onBtnAutoLockEnable() {
        if connectedPeripheral != nil {
            vescController.terminal(cmd: "ul \(password) enable").forEach { chunk in
                self.connectedPeripheral.writeValue(chunk, for: txCharacteristic, type: txWriteType)
            }
        } else {
            let alert = UIAlertController(title: "Not connected", message: "", preferredStyle: .alert)
            let actionCancel = UIAlertAction(title: "Ok", style: .destructive) { action in }
            alert.addAction(actionCancel)
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    @IBAction func onBtnLock() {
        if connectedPeripheral != nil {
            vescController.terminal(cmd: "lk").forEach { chunk in
                self.connectedPeripheral.writeValue(chunk, for: txCharacteristic, type: txWriteType)
            }
        } else {
            let alert = UIAlertController(title: "Not connected", message: "", preferredStyle: .alert)
            let actionCancel = UIAlertAction(title: "Ok", style: .destructive) { action in }
            alert.addAction(actionCancel)
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    @IBAction func onBtnAutoUnlockDisable() {
        if connectedPeripheral != nil {
            print("MAX LENGTH \(connectedPeripheral.maximumWriteValueLength(for: txWriteType))")
            vescController.terminal(cmd: "ul \(password) disable").forEach { chunk in
                self.connectedPeripheral.writeValue(chunk, for: txCharacteristic, type: txWriteType)
            }
        } else {
            let alert = UIAlertController(title: "Not connected", message: "", preferredStyle: .alert)
            let actionCancel = UIAlertAction(title: "Ok", style: .destructive) { action in }
            alert.addAction(actionCancel)
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    //MARK: CustomFunctions
    func stopSearchReader(){
        centralManager.stopScan()
        
        let alert = UIAlertController(title: "Search device", message: "Choose device", preferredStyle: .actionSheet)
        
        for periperal in peripherals {
            let action = UIAlertAction(title: periperal.name ?? "no-name", style: .default) { action in
                self.centralManager.connect(periperal, options: nil)
            }
            alert.addAction(action)
        }
        let actionCancel = UIAlertAction(title: "Cancel", style: .destructive) { action in
            
        }
        alert.addAction(actionCancel)
        
        self.present(alert, animated: true, completion: nil)
    }
    
    func doGetValues(){
        timerValues = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: { (timer) in
            self.connectedPeripheral.writeValue(self.vescController.dataForGetValues(), for: self.txCharacteristic, type: self.txWriteType)
        })
    }
    func presentData(dataVesc : mc_values){
        let wheelDiameter = 700.0 //mm diameter
        let motorDiameter = 63.0 //mm diameter
        let gearRatio : Double = motorDiameter / wheelDiameter
        let motorPoles = 14.0

        let ratioRpmSpeed = gearRatio * 60.0 * wheelDiameter * Double.pi / ((motorPoles / 2.0) * 1000000.0) // ERPM to Km/h
        let ratioPulseDistance = gearRatio * wheelDiameter * Double.pi / ((motorPoles * 3.0) * 1000000.0) // Pulses to km travelled

        let speed = dataVesc.rpm * ratioRpmSpeed
        let distance = Double(dataVesc.tachometer_abs) * ratioPulseDistance
        let power = dataVesc.current_in * dataVesc.v_in
                        
        arrPedalessData = [
            ["title":"Temp MOSFET","data":String(format:"%.2f degC",dataVesc.temp_mos)],
            ["title":"Ah Discharged","data":String(format:"%.4f Ah",dataVesc.amp_hours)],
            ["title":"Ah Charged","data":String(format:"%.4f Ah",dataVesc.amp_hours_charged)],
            ["title":"Motor Current","data":String(format:"%.2f A",dataVesc.current_motor)],
            ["title":"Battery Current","data":String(format:"%.2f A",dataVesc.current_in)],
            ["title":"Watts Discharged","data":String(format:"%.4f Wh" ,dataVesc.watt_hours)],
            ["title":"Watts Charged","data":String(format:"%.4f Wh" ,dataVesc.watt_hours_charged)],
            ["title":"Power","data":String(format:"%.f W",power)],
            ["title":"Distance","data":String(format:"%.2f km", distance)],
            ["title":"Speed","data":String(format:"%.1f km/h",speed)],
            ["title":"Fault Code","data":String(format: "%d",dataVesc.fault_code)],
            ["title":"Voltage","data":String(format:"%.2f V",dataVesc.v_in)],
        ];
        
        tblPedalessData.reloadData()
    }
    
    //MARK: CentralManagerDelegates
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        var message = "Bluetooth"
        switch (central.state) {
        case .unknown: message = "Bluetooth Unknown."; break
        case .resetting: message = "The update is being started. Please wait until Bluetooth is ready."; break
        case .unsupported: message = "This device does not support Bluetooth low energy."; break
        case .unauthorized: message = "This app is not authorized to use Bluetooth low energy."; break
        case .poweredOff: message = "You must turn on Bluetooth in Settings in order to use the reader."; break
        default: break;
        }
        print("Bluetooth: " + message);
    }
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        if !peripherals.contains(peripheral) && ((peripheral.name?.isEmpty) != nil) {
            peripherals.append(peripheral)
        }
    }
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        connectedPeripheral = peripheral
        txCharacteristic = nil
        
        connectedPeripheral.delegate = self
        connectedPeripheral.discoverServices(nil)
    }
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        if error != nil {
            print("FailToDisconnect " + error!.localizedDescription)
            return
        }
        vescController.resetPacket()
    }
    
    //MARK: PeripheralDelegates
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if error != nil {
            print("Error receiving notification for characteristic \(characteristic) : " + error!.localizedDescription)
            return
        }
        if vescController.process_incoming_bytes(incomingData: characteristic.value!) > 0 {
            presentData(dataVesc: vescController.readPacket())
        }
    }
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        for service in peripheral.services!{
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        for characteristic in service.characteristics! {

            if characteristic.uuid.uuidString.contains("0002") {
                txCharacteristic = characteristic
                txWriteType = characteristic.properties == .write ? .withResponse : .withoutResponse
            }
            
            if characteristic.uuid.uuidString.contains("0003") {
                peripheral.setNotifyValue(true, for: characteristic)
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.doGetValues()
        }
    }
    
    //MARK: TableViewDelegates
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return arrPedalessData.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "DataCell", for: indexPath)
        
        let data = arrPedalessData[indexPath.row]
        
        cell.textLabel?.text = data["data"]
        cell.detailTextLabel?.text = data["title"]
        
        return cell
    }
    
    //MARK: ViewDelegates
    override func viewDidLoad() {
        super.viewDidLoad()
        centralManager = CBCentralManager.init(delegate: self, queue: nil)
        vescController = VESC()
    }
}

