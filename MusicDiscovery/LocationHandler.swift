//
//  LocationHandler.swift
//  MusicDiscovery
//
//  Created by Dillon McCusker on 4/6/15.
//  Copyright (c) 2015 Nick Martinson. All rights reserved.
//

import Foundation
import CoreLocation
import UIKit

private let _LocationHandlerSharedInstance = LocationHandler()

protocol LocationAlertProtocol{
    func getAndPushAlert (_: UIAlertController) -> Void
}

protocol MapUpdateProtocol{
    func setMapLocation () -> Void
    func updateMapViewToCamera () -> Void
    func updateMapViewToBearing() -> Void
    func checkMapExistence() -> Bool
    var  mapSetup: Bool {get}
}

protocol MapLocationNotificationProtocol{
    func notifyLocationHandler () -> Void
}

protocol LoginLocationNotificationProtocol{
    func notifyLocationHandler () -> Void
    func locationIsReady() -> Void
    var  userCreated: Bool {get}
}

class LocationHandler: NSObject, CLLocationManagerDelegate{

    class var sharedInstance: LocationHandler {
        return _LocationHandlerSharedInstance
    }
    
    var mapLocNotDelegate: MapLocationNotificationProtocol!
    var loginLocNotDelegate: LoginLocationNotificationProtocol!
    var mapUpdateDelgate: MapUpdateProtocol!
    var locationAlertDelegate: LocationAlertProtocol!
    
    var loginViewLoaded = false
    
    
    var locationManager: CLLocationManager!
    
    var latitude: String!
    var longitude: String!
    var location2D: CLLocationCoordinate2D!
    
    //This variable holds the direction to which the device is pointed in degrees
    var bearing: CLHeading!
    
    var gpsLocatationSet: Bool!
    
    var mapViewExists: Bool = false
    
    var seenError = false
    
    var userID: String!
    
    
    /*********************************************************************************************
    * 4/6/2015
    * Author: Dillon McCusker
    * This initializer sets up CoreLocation services.
    **********************************************************************************************/
    override init() {
        super.init()
//        println("location handler init")
        
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        //moved line so that filter is increased once location has been updated at least once
        locationManager.distanceFilter = 1
    }
    
    func compassInit() -> Void {
        if CLLocationManager.headingAvailable() == false {
            //need alertController for this
            print("This device does not have the ability to measure magnetic fields.")
        } else {
            locationManager.headingFilter = 2 //The default value of this property is 1 degree
            //            locationManager.headingOrientation = ? // https://developer.apple.com/library/prerelease/ios/documentation/CoreLocation/Reference/CLLocationManager_Class/index.html#//apple_ref/occ/instp/CLLocationManager/headingOrientation
            locationManager.startUpdatingHeading()
        }
    }
    
    func locationManagerShouldDisplayHeadingCalibration(manager: CLLocationManager) -> Bool {
        return true
    }

    /*********************************************************************************************
    * 4/15/2015
    * Author: Dillon McCusker
    * function: locationManager
    * Input(s): 
    *    1) CLLocationManager
    *    2) CLHeading <<<
    * Outputs: Void <<<
    * Description:
    *   >>> This function is called when the CLHeading is updated, meaning magnetnic direction has
    *     > likely changed. <<<
    **********************************************************************************************/
    func locationManager(manager: CLLocationManager,
        didUpdateHeading newHeading: CLHeading) {
        
        self.bearing = newHeading
    
//        println("Udated Heading")
//        println("\t\(newHeading)")
            
        if mapViewExists  == true {
            if mapUpdateDelgate.mapSetup == true {
//                println("Should be updating map view from locationhandler")
                mapUpdateDelgate.updateMapViewToBearing()
            }
        }
    }

    /*********************************************************************************************
    * 4/6/2015
    * Author: Dillon McCusker
    * This function is called when CLLocationManager updates current location in the background.
    * TODO: Handle new coordinate data here.
    **********************************************************************************************/
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        print("locations = \(locations)")

        
        let locationArray = locations as NSArray
        let locationObj = locationArray.lastObject as! CLLocation
        let coord = locationObj.coordinate
//        self.bearing = locationObj.course as CLLocationDirection
//        println(coord.latitude)
//        println(coord.longitude)
        
        self.location2D = coord
        self.latitude = "\(coord.latitude)"
        self.longitude = "\(coord.longitude)"
        gpsLocatationSet = true
        
        //Tell LoginVC that the location is ready
        
        if loginViewLoaded {
            if loginLocNotDelegate.userCreated == false {
                loginLocNotDelegate.locationIsReady()
            }
        }
        
        //setup the mapview and cameraposition for the first time
        if mapViewExists == true {
            if mapUpdateDelgate.mapSetup  == false {
                mapUpdateDelgate.setMapLocation()
            }
        }
        //update the map's camera position
        if mapViewExists == true {
            if mapUpdateDelgate.mapSetup == true {
//                mapUpdateDelgate.updateMapViewTarget()
                mapUpdateDelgate.updateMapViewToCamera()
            }
        }
        if self.userID != nil {
            print("Location handler updating backend")
            BluemixCommunication().updateLocation(self.userID, lat: self.latitude, lon: self.longitude)
        }
    }
    
    /*********************************************************************************************
    * 4/6/2015
    * Author: Dillon McCusker
    * This function is called when authorization status changes in CLLocationManager.
    **********************************************************************************************/
    func locationManager(manager: CLLocationManager,
        didChangeAuthorizationStatus status: CLAuthorizationStatus)
    {
        switch status {
        case .NotDetermined:
            locationManager.requestAlwaysAuthorization()
//            locationManager.requestWhenInUseAuthorization()
            print("authorizationSatus is .NotDetermined at initLocationManager()")
        case .Restricted:
            print("authorizationSatus is .Restricted at initLocationManager()")
        case .Denied:
            print("authorizationSatus is .Denied at initLocationManager()")
            ////Use function in protocol to push the alert about location settings
            var locServicesAlertController: UIAlertController = buildTurnOnLocationAlertController()
            locationAlertDelegate.getAndPushAlert(locServicesAlertController)
        case .AuthorizedAlways:
            print("authorizationSatus is .AuthorizedAlways at initLocationManager()")
        case .AuthorizedWhenInUse:
          print("authorizationSatus is .AuthorizedWhenInUse at initLocationManager()")
//            var locServicesAlertController: UIAlertController = buildAuthAlwaysAlertController()
//            locationHandlerDelegate.getAndPushAlert(locServicesAlertController)
        default:
            print("did not find a matching auth in switch statement")
        }
        

        if status == .AuthorizedAlways || status == .AuthorizedWhenInUse {
            //Start up dating location and magnetic heading
            self.compassInit()
            locationManager.startUpdatingLocation()
        } else {
            gpsLocatationSet = false
        }
    }
    
    /*********************************************************************************************
    * 4/6/2015
    * Author: Dillon McCusker
    * This function is provided by CLLocationManager. It will be called when location services 
    * fail with error.
    * Function stops location updates and prints an error, one time.
    **********************************************************************************************/
    func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
//        locationManager.stopUpdatingLocation()
//        if ((error) != nil) {
//            if (seenError == false) {
//                seenError = true
//                print(error, terminator: "")
//            }
//        }
    }

    /*********************************************************************************************
    * 4/7/2015
    * Author: Dillon McCusker
    * Function returns an alertController that may be pushed in a view controller.
    **********************************************************************************************/
    func buildTurnOnLocationAlertController() -> UIAlertController {
        
        let alertController = UIAlertController(
            title: "Turn On Location Services",
            message: "You must turn on Location Services in Settings > Privacy > Location Services to use this app.",
            preferredStyle: .Alert
        )
        let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
        alertController.addAction(cancelAction)
        let openAction = UIAlertAction(title: "Open App Settings", style: .Default) { (action) in
            if let url = NSURL(string:UIApplicationOpenSettingsURLString) {
                UIApplication.sharedApplication().openURL(url)
            }
        }
        alertController.addAction(openAction)
        return alertController
    }
    
    /*********************************************************************************************
    * 4/7/2015
    * Author: Dillon McCusker
    * Function returns an alertcontroller that may be pushed in a view controller.
    **********************************************************************************************/
    func buildAuthAlwaysAlertController() -> UIAlertController {
        
        let alertController = UIAlertController(
            title: "Background Location Access Disabled",
            message: "To use this app and discover music near you, please open this app's settings and set location access to 'Always'.",
            preferredStyle: .Alert
        )
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
        alertController.addAction(cancelAction)
                let openAction = UIAlertAction(title: "Open App Settings", style: .Default) { (action) in
            if let url = NSURL(string:UIApplicationOpenSettingsURLString) {
                UIApplication.sharedApplication().openURL(url)
            }
        }
        alertController.addAction(openAction)
        return alertController
    }
}