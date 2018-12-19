//
//  CustomPin.swift
//  RescuerApp
//
//  Created by CNC on 19/12/2561 BE.
//

import UIKit
import MapKit
import CoreLocation

class CustomPin: NSObject, MKAnnotation {
    var coordinate: CLLocationCoordinate2D
    var title: String?
    var subtitle: String?
    
    init(pinTitle:String, pinSubTitle:String, location:CLLocationCoordinate2D) {
        self.title = pinTitle
        self.subtitle = pinSubTitle
        self.coordinate = location
    }
}
