//
//  User.swift
//  HeroRescueOfficerApp
//
//  Created by CNC on 16/12/2561 BE.
//

import FirebaseFirestore

class Request  {
    
    var documentID: String
    
    var phoneNumber: String
    var requestLocation: GeoPoint
    
    var rescuerID: String?
    var rescuerLocation: GeoPoint?
    var rescuerName: String?
    var status: Int
    
    init(
        documentID: String,
        phoneNumber: String,
        requestLocation: GeoPoint,
        rescuerID: String,
        rescuerLocation: GeoPoint,
        rescuerName: String,
        status: Int
        ) {
        self.documentID = documentID
        self.phoneNumber = phoneNumber
        self.requestLocation = requestLocation
        self.rescuerID = rescuerID
        self.requestLocation = requestLocation
        self.status = status
    }
    
    init (documentID: String,
          phoneNumber: String,
          requestLocation: GeoPoint,
          status: Int) {
        self.documentID = documentID
        self.phoneNumber = phoneNumber
        self.requestLocation = requestLocation
        self.status = status
    }
    
    convenience init?(document: DocumentSnapshot) {
        guard let data = document.data() else { return nil }
        if (data["status"] as! Int == 0) {
            self.init(documentID: document.documentID,
                      phoneNumber: data["phoneNumber"] as! String,
                      requestLocation: data["requestLocation"] as! GeoPoint,
                      status: data["status"] as! Int)
        } else {
            self.init(documentID: document.documentID,
                      phoneNumber: data["phoneNumber"] as! String,
                      requestLocation: data["requestLocation"] as! GeoPoint,
                      rescuerID: data["rescuerID"] as! String,
                      rescuerLocation: data["rescuerLocation"] as! GeoPoint,
                      rescuerName: data["rescuerName"] as! String,
                      status: data["status"] as! Int)
        }
        
    }
    
    convenience init?(document: QueryDocumentSnapshot) {
        let data = document.data()
        if (data["status"] as! Int == 0) {
            print("Document.data(): \(data)")
            self.init(documentID: document.documentID,
                      phoneNumber: data["phoneNumber"] as! String,
                      requestLocation: data["requestLocation"] as! GeoPoint,
                      status: data["status"] as! Int)
        } else {
            print("Document.data(): \(data)")
            self.init(documentID: document.documentID,
                      phoneNumber: data["phoneNumber"] as! String,
                      requestLocation: data["requestLocation"] as! GeoPoint,
                      rescuerID: data["rescuerID"] as! String,
                      rescuerLocation: data["rescuerLocation"] as! GeoPoint,
                      rescuerName: data["rescuerName"] as! String,
                      status: data["status"] as! Int)
        }
    }
    
}
