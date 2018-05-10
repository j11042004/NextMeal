//
//  AddressManager.swift
//  NextLaunch
//
//  Created by Uran on 2018/3/20.
//  Copyright © 2018年 Uran. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation
class AddressManager: NSObject {
    public static let shared = AddressManager()
    
    /// 將 座標轉換成 地址
    ///
    /// - Parameters:
    ///   - coordinate: 輸入的座標，CLLocationCoordinate2D
    ///   - completion: 回傳 Closure ，是否有成功:Bool，是否有錯誤:Error?，地址，String?
    public func coordinateToAddress(With coordinate: CLLocationCoordinate2D ,
                                    completion : @escaping (_ success:Bool ,
                                                             _ error : Error? ,
                                                        _ addressName:String?) -> Void){
        let storeLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        let geoCoder = CLGeocoder()
        geoCoder.reverseGeocodeLocation(storeLocation) { (places, error) in
            if let error = error{
                NSLog("座標轉地址失敗 error : \(error.localizedDescription)")
                completion(false , error ,nil)
                return
            }
            guard let places = places else{
                completion(false , nil ,nil)
                NSLog("places is nil")
                return
            }
            for place in places{
                let name = place.name
                completion(true , nil ,name)
            }
        }
    }
    /// 將 地址轉換成 座標
    ///
    /// - Parameters:
    ///   - address: 輸入的地址，String
    ///   - completion: 回傳 Closure ，是否有成功:Bool，是否有錯誤:Error?，座標，CLLocationCoordinate2D?
    public func addressToCoordinate(With address : String ,
                                    mapView : MKMapView ,
                                    completion : @escaping (_ success:Bool ,
                                                              _ error:Error? ,
                                                         _ coordinates:CLLocationCoordinate2D?) -> Void){
        let request = MKLocalSearchRequest()
        request.naturalLanguageQuery = address
        request.region = mapView.region
        let search = MKLocalSearch(request: request)
        search.start(completionHandler: { (response, error) in
            if let error = error {
                NSLog("address change error : \(error.localizedDescription)")
                completion(false,error,nil)
                return
            }
            guard let response = response else{
                completion(false,nil,nil)
                return
            }

            for item in response.mapItems{
                let coordinate = item.placemark.coordinate
                completion(true,nil,coordinate)
            }
        })
    }
    
}
