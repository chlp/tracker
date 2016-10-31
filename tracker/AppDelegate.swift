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


@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, CLLocationManagerDelegate {

    var window: UIWindow?
    var locationManager: CLLocationManager!
    var cloudUrlString = "https://steptracker.tw1.ru/track.php"
    var lastUpdateTime : Date!
    
    func deviceUuid() -> String {
        return (UIDevice.current.identifierForVendor?.uuidString)!
    }
    
    func sendJson(urlString: String, data: Any) -> Bool {
        var jsonData : Data
        do {
            jsonData = try JSONSerialization.data(withJSONObject: data, options: JSONSerialization.WritingOptions.prettyPrinted)
        } catch {
            print("json error")
            return false
        }

        let url = URL(string: urlString)!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData

        let semaphore = DispatchSemaphore(value: 0)

        var httpError = false
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                print("error=\(error)")
                httpError = true
                semaphore.signal()
                return
            }

            if let httpStatus = response as? HTTPURLResponse, httpStatus.statusCode != 200 {
                print("statusCode should be 200, but is \(httpStatus.statusCode)")
                print("response = \(response)")
                httpError = true
            }

            let responseString = String(data: data, encoding: .utf8)
            print("responseString = \(responseString)")
            semaphore.signal()
        }
        task.resume()

        semaphore.wait()

        print("err", httpError)
        return !httpError
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        print("application")
        
        lastUpdateTime = Date.init(timeIntervalSince1970: 0)

        if (!CLLocationManager.locationServicesEnabled()) {
            print("No location manager. Exit")
            exit(0)
        }

        UIDevice.current.isBatteryMonitoringEnabled = true

        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestAlwaysAuthorization()
        locationManager.startUpdatingLocation()

        return true
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let location = locations.last! as CLLocation

        let success = sendJson(urlString: cloudUrlString, data: [
            "deviceId": deviceUuid(),
            "latitude": location.coordinate.latitude,
            "longitude": location.coordinate.longitude,
            "speed": location.speed,
            "batteryState": UIDevice.current.batteryState.rawValue,
            "batteryLevel": UIDevice.current.batteryLevel,
            "deviceModel": UIDevice.current.model,
            "deviceLocalizedModel": UIDevice.current.localizedModel,
            "deviceName": UIDevice.current.name,
            "deviceSystemName": UIDevice.current.systemName,
            "deviceSystemVersion": UIDevice.current.systemVersion
        ])

        print("suc", success)
        if (success) {
            lastUpdateTime = Date.init()
        }

        let viewController = window?.rootViewController as! ViewController
        let interval : TimeInterval = Date().timeIntervalSince(lastUpdateTime)
        let intervalSeconds = Int(interval)
        viewController.mySetLabelText(text: String(intervalSeconds))
    }

    func applicationWillResignActive(_ application: UIApplication) {
        print("applicationWillResignActive")
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        print("applicationDidEnterBackground")
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        print("applicationWillEnterForeground")
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        print("applicationDidBecomeActive")
    }

    func applicationWillTerminate(_ application: UIApplication) {
        print("applicationWillTerminate")
    }
}

