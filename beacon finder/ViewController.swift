//
//  ViewController.swift
//  beacon finder
//
//  Created by 조대희 on 2017. 12. 1..
//  Copyright © 2017년 AsiaQuest.inc. All rights reserved.
//

import UIKit
import Foundation
import CoreLocation
import CoreBluetooth
class ViewController: UIViewController, CLLocationManagerDelegate, CBCentralManagerDelegate{
    @IBOutlet var Status: UILabel!
    @IBOutlet var UUID: UILabel!
    @IBOutlet var Major: UILabel!
    @IBOutlet var Minor: UILabel!
    @IBOutlet var RSSI: UILabel!
    
    
    //UUIDからNSUUIDを作成
    let services = [CBUUID(string: "FEAA")]
    var proximityUUID:NSUUID? = NSUUID(uuidString:"78907890-7890-7890-7890-789078907890")
    var region: CLBeaconRegion!
    var locationManager: CLLocationManager!
    var centralManager: CBCentralManager!
    var peripheral: CBPeripheral!

    override func viewDidLoad() {
        super.viewDidLoad()
        self.locationManager = CLLocationManager()
        self.locationManager.delegate = self
        self.centralManager = CBCentralManager(delegate: self,queue: nil)
        //CLBeaconRegionを生成
        self.region = CLBeaconRegion(proximityUUID:proximityUUID! as UUID, identifier:"EstimateRegion")
        centralManager.scanForPeripherals(withServices: services, options: nil)
        self.UUID.text = proximityUUID?.uuidString
        //デリゲートの設定
        locationManager.delegate = self
        
    }

        func locationManager(_ locationManager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
            switch status {
            case .notDetermined:
                print("許可承認")
                self.Status.text = "Starting Monitor"
                //デバイスに許可を促す
                    self.locationManager.requestWhenInUseAuthorization()
                    self.locationManager.startRangingBeacons(in: self.region)
                break
            case .authorizedAlways:
                //iBeaconによる領域観測を開始する
                print("観測開始")
                self.Status.text = "Starting Monitor"
                self.locationManager.startRangingBeacons(in: self.region)
           
            case .authorizedWhenInUse:
                print("観測開始")
                self.Status.text = "Starting Monitor"
                self.locationManager.startRangingBeacons(in: self.region)
                break
            case .denied,.restricted:
                 print("位置情報取得が拒否されました")
                 self.Status.text = "位置情報取得が拒否されました"
                 break
 
            }
    
    }    //以下 CCLocationManagerデリゲートの実装---------------------------------------------->
    
    /*
     - (void)locationManager:(CLLocationManager *)manager didStartMonitoringForRegion:(CLRegion *)region
     Parameters
     manager : The location manager object reporting the event.
     region  : The region that is being monitored.
     */
    func locationManager(_ locationManager: CLLocationManager, didStartMonitoringFor region: CLRegion) {
        locationManager.requestState(for: region)
        self.Status.text = "Scanning..."
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        print("state: \(central.state)")
    }
    
    func centralManager(
        central: CBCentralManager,
        didDiscoverPeripheral peripheral: CBPeripheral,
        advertisementData: [String : AnyObject],
        RSSI: NSNumber)
    {
        let serviceData = advertisementData[CBAdvertisementDataServiceDataKey] as? [CBUUID : NSData]
        
        let eddystoneServiceData = serviceData![CBUUID(string: "FEAA")]
        
    }
    enum EddystoneFrameType {
        case UID
        case URL
        case TLM
        case Unknown
    }
     func frameTypeForEddystoneServiceData(data: NSData) -> EddystoneFrameType {
        
        var bytes = [UInt8](repeating: 0, count: data.length)
        data.getBytes(&bytes, length: data.length)
        let firstByte = bytes[0]
        
        if firstByte == 0x00 {
            return .UID
        }
        else if firstByte == 0x10 {
            return .URL
        }
        else if firstByte == 0x20 {
            return .TLM
        }
        return .Unknown
    }
    /*
     - (void)locationManager:(CLLocationManager *)manager didDetermineState:(CLRegionState)state forRegion:(CLRegion *)region
     Parameters
     manager :The location manager object reporting the event.
     state   :The state of the specified region. For a list of possible values, see the CLRegionState type.
     region  :The region whose state was determined.
     */
    func locationManager(_ locationManager: CLLocationManager, didDetermineState state: CLRegionState, for inRegion: CLRegion) {
        if (state == .inside) {
            //領域内にはいったときに距離測定を開始
            locationManager.startRangingBeacons(in: self.region)
        }
    }
    
    /*
     リージョン監視失敗（bluetoothの設定を切り替えたりフライトモードを入切すると失敗するので１秒ほどのdelayを入れて、再トライするなど処理を入れること）
     - (void)locationManager:(CLLocationManager *)manager monitoringDidFailForRegion:(CLRegion *)region withError:(NSError *)error
     Parameters
     manager : The location manager object reporting the event.
     region  : The region for which the error occurred.
     error   : An error object containing the error code that indicates why region monitoring failed.
     */
    private func locationManager(locationManager: CLLocationManager!, monitoringDidFailForRegion region: CLRegion!, withError error: NSError!) {
        print("monitoringDidFailForRegion \(error)")
        self.Status.text = "Error :("
    }
    
    /*
     - (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
     Parameters
     manager : The location manager object that was unable to retrieve the location.
     error   : The error object containing the reason the location or heading could not be retrieved.
     */
    //通信失敗
    func locationManager(locationManager: CLLocationManager!, didFailWithError error: Error!,_: Error!) {
        print("didFailWithError \(error)")
    }
    
    func locationManager(_ locationManager: CLLocationManager, didEnterRegion region: CLRegion) {
        locationManager.startRangingBeacons(in: region as! CLBeaconRegion)
        self.Status.text = "Possible Match"
    }
    
     func locationManager(_ locationManager : CLLocationManager, didExitRegion region: CLRegion) {
        locationManager.stopRangingBeacons(in: region as! CLBeaconRegion)
        reset()
    }
    
    /*
     beaconsを受信するデリゲートメソッド。複数あった場合はbeaconsに入る
     - (void)locationManager:(CLLocationManager *)manager didRangeBeacons:(NSArray *)beacons inRegion:(CLBeaconRegion *)region
     Parameters
     manager : The location manager object reporting the event.
     beacons : An array of CLBeacon objects representing the beacons currently in range. You can use the information in these objects to determine the range of each beacon and its identifying information.
     region  : The region object containing the parameters that were used to locate the beacons
     */
    func locationManager(_ locationManager: CLLocationManager, didRangeBeacons beacons: [CLBeacon], in region: CLBeaconRegion) {
        print(beacons)

     if(beacons.count == 0) { return }
        else {//複数あった場合は一番先頭のものを処理する
        var beacon = beacons[0]
        
       /*
         beaconから取得できるデータ
         proximityUUID   :   regionの識別子
         major           :   識別子１
         minor           :   識別子２
         rssi            :   電波強度
         */
        if beacon.rssi > -40  {
        self.Status.text   = "OK"
  //      self.UUID.text     = beacon.proximityUUID.uuidString
        self.Major.text    = "\(beacon.major) (DEC)/ " + String(Int("\(beacon.major)")!, radix: 16) + "(HEX)"
        self.Minor.text    = "\(beacon.minor) (DEC)/ " + String(Int("\(beacon.minor)")!, radix: 16) + "(HEX)"
        self.RSSI.text     = "\(beacon.rssi)"
        }
        else {
       reset()
        }
        }
    }
    
 func reset(){
        self.Status.text   = "too far"
        self.UUID.text     = proximityUUID?.uuidString
        self.Major.text    = "none"
        self.Minor.text    = "none"
        self.RSSI.text     = "none"
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
           
}



