//
//  AppDelegate.swift
//  tracker
//
//  Created by Alexey on 30.10.16.
//  Copyright © 2016 bamj.pro. All rights reserved.
//

import UIKit
import Darwin
import CoreLocation


let CLOUD_URL:String = "https://steptracker.tw1.ru/track.php"
let LOCATIONS_QUEUE_LIMIT = 99

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, CLLocationManagerDelegate {

    var window: UIWindow?
    var locationManager: CLLocationManager!
    var lastLocationTime : Date!
    var lastSendTime : Date!
    var timer : Timer!
    var locationsMarkersArr : [Data]!

    func deviceUuid() -> String {
        return (UIDevice.current.identifierForVendor?.uuidString)!
    }

    func sendLocationsToCloud() {
        if (locationsMarkersArr.count == 0) {
            return
        }

        var request = URLRequest(url: URL(string: CLOUD_URL)!)
        request.httpMethod = "POST"
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        request.httpBody = locationsMarkersArr.remove(at: 0)

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let _ = data, error == nil else {
                print("error=\(error)")
                return
            }

            if let httpStatus = response as? HTTPURLResponse, httpStatus.statusCode != 200 {
                print("statusCode should be 200, but is \(httpStatus.statusCode)")
                print("response = \(response)")
            } else {
                print(Date(), "success sendLocation")
                self.lastSendTime = Date.init()
            }
        }
        task.resume()
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        print("application")

        locationsMarkersArr = []
        lastSendTime = Date.init(timeIntervalSince1970: 0)
        lastLocationTime = Date.init(timeIntervalSince1970: 0)

        if (!CLLocationManager.locationServicesEnabled()) {
            print("No location manager. Exit")
            exit(0)
        }

        UIDevice.current.isBatteryMonitoringEnabled = true

        timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(timerEvent), userInfo: nil, repeats: true)

        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters // kCLLocationAccuracyBestForNavigation kCLLocationAccuracyBest
        locationManager.distanceFilter = 10.0
//        locationManager.headingFilter = 5
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.requestAlwaysAuthorization()
        locationManager.startUpdatingLocation()

        return true
    }

    func timerEvent() {
        print("timer")
        let viewController = window?.rootViewController as! ViewController
        let intervalSend = String(Int(Date().timeIntervalSince(lastSendTime)))
        let intervalLocation = String(Int(Date().timeIntervalSince(lastLocationTime)))
        viewController.mySetLabelText(text: "send:" + intervalSend + ", location:" + intervalLocation)
        sendLocationsToCloud()
    }

    func updateLocation() {
        let location = locationManager.location! as CLLocation
        let jsonData = try! JSONSerialization.data(withJSONObject: [
            "deviceId": deviceUuid(),
            "latitude": location.coordinate.latitude,
            "longitude": location.coordinate.longitude,
            "timestamp": Date().timeIntervalSince1970,
            "speed": location.speed,
            "batteryState": UIDevice.current.batteryState.rawValue,
            "batteryLevel": UIDevice.current.batteryLevel,
            //            "deviceModel": UIDevice.current.model,
            //            "deviceLocalizedModel": UIDevice.current.localizedModel,
            "deviceName": UIDevice.current.name,
            //            "deviceSystemName": UIDevice.current.systemName,
            //            "deviceSystemVersion": UIDevice.current.systemVersion
        ])
        if (locationsMarkersArr.count >= LOCATIONS_QUEUE_LIMIT) {
            locationsMarkersArr.remove(at: Int(arc4random_uniform(UInt32(LOCATIONS_QUEUE_LIMIT))))
        }
        locationsMarkersArr.append(jsonData)
        lastLocationTime = Date.init()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        updateLocation()
    }

    func applicationWillResignActive(_ application: UIApplication) {
        print("applicationWillResignActive")
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        print("applicationDidEnterBackground")
//        timer.invalidate()
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        print("applicationWillEnterForeground")
//        timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(timerEvent), userInfo: nil, repeats: true)
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        print("applicationDidBecomeActive")
    }

    func applicationWillTerminate(_ application: UIApplication) {
        print("applicationWillTerminate")
    }
}

