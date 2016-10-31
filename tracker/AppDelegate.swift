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


@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, CLLocationManagerDelegate {

    var window: UIWindow?
    var locationManager: CLLocationManager!
    var lastUpdateTime : Date!
    var timer : Timer!

    func deviceUuid() -> String {
        return (UIDevice.current.identifierForVendor?.uuidString)!
    }

    func sendLocationsToCloud(urlString: String, data: Any) {
        var jsonData : Data
        do {
            jsonData = try JSONSerialization.data(withJSONObject: data)
        } catch {
            print("json error")
            return
        }

        var request = URLRequest(url: URL(string: urlString)!)
        request.httpMethod = "POST"
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let _ = data, error == nil else {
                print("error=\(error)")
                return
            }

            if let httpStatus = response as? HTTPURLResponse, httpStatus.statusCode != 200 {
                print("statusCode should be 200, but is \(httpStatus.statusCode)")
                print("response = \(response)")
            } else {
                print(Date(), "success update")
                self.lastUpdateTime = Date.init()
            }
        }
        task.resume()
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        print("application")
        
        lastUpdateTime = Date.init(timeIntervalSince1970: 0)

        if (!CLLocationManager.locationServicesEnabled()) {
            print("No location manager. Exit")
            exit(0)
        }

        UIDevice.current.isBatteryMonitoringEnabled = true

        timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(timerEvent), userInfo: nil, repeats: true)

        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation // kCLLocationAccuracyNearestTenMeters // kCLLocationAccuracyBest
//        locationManager.distanceFilter = 1.0
//        locationManager.headingFilter = 5
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.requestAlwaysAuthorization()
        locationManager.startUpdatingLocation()

        return true
    }

    func timerEvent() {
        print("timer")
        let viewController = window?.rootViewController as! ViewController
        let interval : TimeInterval = Date().timeIntervalSince(lastUpdateTime)
        let intervalSeconds = Int(interval)
        viewController.mySetLabelText(text: String(intervalSeconds))
    }

    func updateLocation() {
        let location = locationManager.location! as CLLocation

        sendLocationsToCloud(urlString: CLOUD_URL, data: [
            "deviceId": deviceUuid(),
            "latitude": location.coordinate.latitude,
            "longitude": location.coordinate.longitude
//            "speed": location.speed,
//            "batteryState": UIDevice.current.batteryState.rawValue,
//            "batteryLevel": UIDevice.current.batteryLevel,
//            "deviceModel": UIDevice.current.model,
//            "deviceLocalizedModel": UIDevice.current.localizedModel,
//            "deviceName": UIDevice.current.name,
//            "deviceSystemName": UIDevice.current.systemName,
//            "deviceSystemVersion": UIDevice.current.systemVersion
        ])
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        updateLocation()
    }

    func applicationWillResignActive(_ application: UIApplication) {
        print("applicationWillResignActive")
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        print("applicationDidEnterBackground")
        timer.invalidate()
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        print("applicationWillEnterForeground")
        timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(timerEvent), userInfo: nil, repeats: true)
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        print("applicationDidBecomeActive")
    }

    func applicationWillTerminate(_ application: UIApplication) {
        print("applicationWillTerminate")
    }
}

