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


let CLOUD_URL: String = "https://steptracker.tw1.ru/track.php"
let LOCATIONS_QUEUE_LIMIT: Int = 99
let LOCATION_UPDATE_INTERVAL: Double = 20
let MIN_GPS_ACCURACY: Double = 300;

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, CLLocationManagerDelegate {

    var window: UIWindow?
    var locationManager: CLLocationManager!
    var lastLocationTime: Date!
    var lastSendTime: Date!
    var timerUpdateLocation: Timer!
    var timerSendLocation: Timer!
    var timerUpdateGui: Timer!
    var locationsMarkersArr: [Data]!
    var previousLocationTime: Date!
    var previousHorizontalAccuracy: Double!

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
        let jsonData = locationsMarkersArr.remove(at: 0)
        request.httpBody = jsonData // todo: вот бы отправлять всю очередь одним запросом

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let _ = data, error == nil else {
                print("error=\(error)")
                self.locationsMarkersArr.append(jsonData)
                return
            }

            if let httpStatus = response as? HTTPURLResponse, httpStatus.statusCode != 200 {
                print("statusCode should be 200, but is \(httpStatus.statusCode)")
                print("response = \(response)")
                self.locationsMarkersArr.append(jsonData)
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
        previousLocationTime = Date.init(timeIntervalSince1970: 0)
        previousHorizontalAccuracy = 0

        if (!CLLocationManager.locationServicesEnabled()) {
            print("No location manager. Exit")
            exit(0)
        }

        UIDevice.current.isBatteryMonitoringEnabled = true

        timerUpdateLocation = Timer.scheduledTimer(timeInterval: LOCATION_UPDATE_INTERVAL, target: self, selector: #selector(timerUpdateLocationEvent), userInfo: nil, repeats: true) // todo: вот бы интервал был обратно пропорционален текущей скорости
        timerSendLocation = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(timerSendLocationEvent), userInfo: nil, repeats: true)
        timerUpdateGui = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(timerUpdateGuiEvent), userInfo: nil, repeats: true)

        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 1
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.requestAlwaysAuthorization()
        locationManager.startMonitoringSignificantLocationChanges()
        locationManager.startUpdatingLocation()

        return true
    }

    func timerUpdateLocationEvent() {
        print("t L")
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 1
    }

    func timerSendLocationEvent() {
        print("t S")
        sendLocationsToCloud()
    }

    func timerUpdateGuiEvent() {
        print("t G")
        let viewController = window?.rootViewController as! ViewController
        let intervalSend = String(Int(Date().timeIntervalSince(lastSendTime)))
        let intervalLocation = String(Int(Date().timeIntervalSince(lastLocationTime)))
        viewController.mySetLabelText(text: "send:" + intervalSend + "\r\nlocation:" + intervalLocation + "\r\nqueue:" + String(locationsMarkersArr.count))
        sendLocationsToCloud()
    }

    func updateLocation() -> Bool {
        let location = locationManager.location! as CLLocation
        let horizontalAccuracy = location.horizontalAccuracy

        print("try updateLocation with horizontalAccuracy:", horizontalAccuracy)
        if (horizontalAccuracy > MIN_GPS_ACCURACY) {
            print("----not updateLocation. Min accuracy")
            return false
        }

        let newLocationTime = Date()
        print("timediff", newLocationTime.timeIntervalSince(previousLocationTime))
        if (newLocationTime.timeIntervalSince(previousLocationTime) < 5) {
            if (Double(horizontalAccuracy) < Double(previousHorizontalAccuracy)) {
                print("----too frequently, but accuracy better. Continue")
            } else {
                print("----not updateLocation. Too frequently")
                return false
            }
        }

        let jsonData = try! JSONSerialization.data(withJSONObject: [
            "deviceId": deviceUuid(),
            "latitude": location.coordinate.latitude,
            "longitude": location.coordinate.longitude,
            "horizontalAccuracy": horizontalAccuracy,
            "verticalAccuracy": location.verticalAccuracy,
            "timestamp": newLocationTime.timeIntervalSince1970,
            "speed": location.speed,
            "batteryState": UIDevice.current.batteryState.rawValue,
            "batteryLevel": UIDevice.current.batteryLevel,
            //            "deviceModel": UIDevice.current.model,
            //            "deviceLocalizedModel": UIDevice.current.localizedModel,
            "deviceName": UIDevice.current.name,
            //            "deviceSystemName": UIDevice.current.systemName,
            //            "deviceSystemVersion": UIDevice.current.systemVersion
            ])
        while (locationsMarkersArr.count >= LOCATIONS_QUEUE_LIMIT) {
            locationsMarkersArr.remove(at: Int(arc4random_uniform(UInt32(LOCATIONS_QUEUE_LIMIT)))) // todo: вот бы удалять результаты с наихудшей точностью
        }
        locationsMarkersArr.append(jsonData)
        lastLocationTime = Date.init()
        previousLocationTime = newLocationTime
        previousHorizontalAccuracy = horizontalAccuracy
        print("----updateLocation")

        return true
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if (updateLocation()) {
            locationManager.desiredAccuracy = kCLLocationAccuracyThreeKilometers
            locationManager.distanceFilter = 999999
        }
    }

    func applicationWillResignActive(_ application: UIApplication) {
        print("applicationWillResignActive")
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        print("applicationDidEnterBackground")
        timerUpdateGui.invalidate()
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        print("applicationWillEnterForeground")
        timerUpdateGui = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(timerUpdateGuiEvent), userInfo: nil, repeats: true)
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        print("applicationDidBecomeActive")
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        print("applicationWillTerminate")
    }
}

