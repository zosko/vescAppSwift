//
//  ViewController.swift
//  VESC_IOS_SWIFT
//
//  Created by Bosko Petreski on 1/21/20.
//  Copyright © 2020 Bosko Petreski. All rights reserved.
//

import UIKit
import CoreBluetooth
import CoreLocation

class Dashboard: UIViewController,CBCentralManagerDelegate,CBPeripheralDelegate,UITableViewDelegate,UITableViewDataSource,CLLocationManagerDelegate{
    
    //MARK: Variables
    var locationManager:CLLocationManager?
    var centralManager: CBCentralManager!
    var connectedPeripheral: CBPeripheral!
    var peripherals : [CBPeripheral] = []
    var txCharacteristic: CBCharacteristic!
    var writeType : CBCharacteristicWriteType = .withoutResponse
    var arrPedalessData : [[String:String]] = []
    var secondStarted = 0
    var timerValues : Timer!
    var vescController : VESC!
    var gpsSpeed = 0.0
    var gpsDistance = 0.0
    var gpsPrevLocation : CLLocation?
    
    //MARK: IBOutlets
    @IBOutlet var tblPedalessData : UITableView!
    @IBOutlet var btnConnect : UIButton!
    
    //MARK: IBActions
    @IBAction func onBtnConnect(){
        if connectedPeripheral != nil {
            btnConnect.setTitle("Connected", for: .normal)
            centralManager.cancelPeripheralConnection(connectedPeripheral)
            timerValues.invalidate()
            timerValues = nil
            connectedPeripheral = nil;
            peripherals.removeAll()
            secondStarted = 0;
        }
        else{
            btnConnect.setTitle("Disconnect", for: .normal)
            peripherals.removeAll()
            centralManager.scanForPeripherals(withServices: [CBUUID(string: "FFE0")], options: nil)
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                self.stopSearchReader()
            }
        }
    }
    
    //MARK: CustomFunctions
    func stopSearchReader(){
        centralManager.stopScan()
        
        let alert = UIAlertController.init(title: "Search device", message: "Choose Pedaless device", preferredStyle: .actionSheet)
        
        for periperal in peripherals{
            let action = UIAlertAction.init(title: periperal.name, style: .default) { (action) in
                self.centralManager.connect(periperal, options: nil)
            }
            alert.addAction(action)
        }
        let actionCancel = UIAlertAction.init(title: "Cancel", style: .destructive) { (action) in
            self.btnConnect.setTitle("Connect", for: .normal)
        }
        alert.addAction(actionCancel)
        
        self.present(alert, animated: true, completion: nil)
    }
    func doGetValues(){
        timerValues = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: { (timer) in
            self.connectedPeripheral.writeValue(self.vescController.dataForGetValues(), for: self.txCharacteristic, type: self.writeType)
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

        let h = secondStarted / 3600
        let m = (secondStarted / 60) % 60
        let s = secondStarted % 60
                        
        arrPedalessData = [["title":"Temp MOSFET","data":String(format:"%.2f degC",dataVesc.temp_mos)],
                           ["title":"Ah Discharged","data":String(format:"%.4f Ah",dataVesc.amp_hours)],
                           ["title":"Ah Charged","data":String(format:"%.4f Ah",dataVesc.amp_hours_charged)],
                           ["title":"Motor Current","data":String(format:"%.2f A",dataVesc.current_motor)],
                           ["title":"Battery Current","data":String(format:"%.2f A",dataVesc.current_in)],
                           ["title":"Watts Discharged","data":String(format:"%.4f Wh" ,dataVesc.watt_hours)],
                           ["title":"Watts Charged","data":String(format:"%.4f Wh" ,dataVesc.watt_hours_charged)],
                           ["title":"Power","data":String(format:"%.f W",power)],
                           ["title":"Distance","data":String(format:"%.2f km", distance)],
                           ["title":"GPS Distance","data":String(format:"%.2f km", gpsDistance)],
                           ["title":"Speed","data":String(format:"%.1f km/h",speed)],
                           ["title":"GPS Speed","data":String(format:"%.1f km/h",gpsSpeed)],
                           ["title":"Fault Code","data":String(format: "%d",dataVesc.fault_code)],
                           ["title":"Drive time","data":String(format:"%ld:%02ld:%02ld", h, m, s)],
                           ["title":"Voltage","data":String(format:"%.2f V",dataVesc.v_in)],
        ];
        
        tblPedalessData.reloadData()

        if(dataVesc.current_motor > 0){
           secondStarted = secondStarted + 1;
        }
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
        if !peripherals.contains(peripheral){
            peripherals.append(peripheral)
        }
    }
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        connectedPeripheral = peripheral
        txCharacteristic = nil
        
        connectedPeripheral.delegate = self
        connectedPeripheral.discoverServices(nil)
    }
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        if error != nil {
            print("FailToConnect" + error!.localizedDescription)
        }
    }
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        if error != nil {
            print("FailToDisconnect" + error!.localizedDescription)
            return
        }
        vescController.resetPacket()
    }
    
    //MARK: PeripheralDelegates
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        if error != nil {
            print("Error receiving didWriteValueFor \(characteristic) : " + error!.localizedDescription)
            return
        }
    }
    func peripheralIsReady(toSendWriteWithoutResponse peripheral: CBPeripheral) {
        
    }
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
            peripheral.discoverCharacteristics([CBUUID (string: "FFE1")], for: service)
        }
    }
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        if error != nil {
            print("Error receiving didUpdateNotificationStateFor \(characteristic) : " + error!.localizedDescription)
            return
        }
    }
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        for characteristic in service.characteristics! {
            
            if characteristic.uuid == CBUUID(string: "FFE1"){
                txCharacteristic = characteristic
                peripheral.setNotifyValue(true, for: characteristic)
                writeType = characteristic.properties == .write ? .withResponse : .withoutResponse
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    self.doGetValues()
                }
            }
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
    
    //MARK: CoreLocation
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            if(location.speed > 0){
                gpsSpeed = location.speed * 3.6
            }
            
            if gpsPrevLocation != nil {
                let distance = location.distance(from: gpsPrevLocation!) / 1000.0
                gpsDistance = gpsDistance + distance
            }
            
            gpsPrevLocation = location
        }
    }
    
    //MARK: ViewDelegates
    override func viewDidLoad() {
        super.viewDidLoad()
        
        centralManager = CBCentralManager.init(delegate: self, queue: nil)
        
        vescController = VESC()
        
        locationManager = CLLocationManager()
        locationManager?.desiredAccuracy = kCLLocationAccuracyBest
        locationManager?.requestAlwaysAuthorization()
        locationManager?.startUpdatingLocation()
        locationManager?.delegate = self
        locationManager?.allowsBackgroundLocationUpdates = true
    }


}

