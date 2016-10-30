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

        var httpError = false
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                print("error=\(error)")
                httpError = true
                return
            }

            if let httpStatus = response as? HTTPURLResponse, httpStatus.statusCode != 200 {
                print("statusCode should be 200, but is \(httpStatus.statusCode)")
                print("response = \(response)")
                httpError = true
            }

            let responseString = String(data: data, encoding: .utf8)
            print("responseString = \(responseString)")
        }
        task.resume()

        return !httpError
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        print("application")

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
        
        print(sendJson(urlString: cloudUrlString, data: [1]))

        return true
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let location = locations.last! as CLLocation

        print(
            deviceUuid(),
            location.coordinate.latitude,
            location.coordinate.longitude,
            location.speed,
            UIDevice.current.batteryState,
            UIDevice.current.batteryLevel,
            UIDevice.current.model,
            UIDevice.current.localizedModel,
            UIDevice.current.name,
            UIDevice.current.systemName,
            UIDevice.current.systemVersion
        )
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

