//
//  SearchViewController.swift
//  NextLaunch
//
//  Created by Uran on 2018/5/8.
//  Copyright © 2018年 Uran. All rights reserved.
//

import UIKit
import CoreLocation
import MapKit
class SearchViewController: UIViewController {
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var searchView: SearchView!
    @IBOutlet weak var nowButton: UIButton!
    
    private let waitingView = WaitingView()
    private let location = Location.shardInstrance
    let search : SearchObject = SearchObject.shardInstance
    let dataSearch = DataSearch.shardInstance
    private var userLocation : CLLocation!
    private var places : [ResultPlace] = [ResultPlace]()
    private var annotations : [MKAnnotation] = [MKAnnotation]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        searchView.delegate = self
        location.requestLocationAllowed()
        self.nowButton.layer.cornerRadius = self.nowButton.frame.width/2
        self.nowButton.layer.masksToBounds = true
        
        self.view.addSubview(self.waitingView)
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.navigationBar.isHidden = true
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.moveRegion(coordinate: self.mapView.userLocation.coordinate, degree: 0.001)
        self.location.delelgate = self
        self.mapView.delegate = self
        self.waitingView.addWaitingViewConstraint(With: self.view)
        self.view.layoutIfNeeded()
        self.waitingView.showing(false)
    }
    @IBAction func moveToUesrLocation(_ sender: UIButton) {
        self.moveRegion(coordinate: self.mapView.userLocation.coordinate, degree: 0.001)
    }
    
    /// 顯示 DataViewController
    func showDataVC(place : ResultPlace? , data : SqlData?) {
        let bundele : Bundle = Bundle(for: DataViewController.self)
        let nextVC = DataViewController(nibName: "DataViewController", bundle: bundele)
        if data != nil {
            nextVC.data = data
        }else if place != nil{
            nextVC.goalPlace = place
        }else{
            return
        }
        // 轉場動畫效果
        let transition = CATransition()
        transition.duration = 0.3
        transition.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionLinear)
        transition.type = kCATransitionReveal
        transition.subtype = kCATransitionFromRight
        // 顯示 data VC
        DispatchQueue.main.async {
            self.view.window?.layer.add(transition, forKey: nil)
            self.present(nextVC, animated: false, completion: nil)
        }
    }
    // 進行 Google map place 搜尋
    func searchData(With place : ResultPlace , completion : (_ data : SqlData?)->Void){
        guard let name = place.name else {
            completion(nil)
            return
        }
        self.dataSearch.searchDataName(query: name) { (datas, errorMessage
            ) in
            guard let datas = datas else{
                completion(nil)
                return
            }
            var placeData : SqlData?
            for data in datas {
                // 判斷 data 的座標是否存在，以及是否等於 place 的座標
                guard let lat = data.latitude,
                      let lon = data.longitude,
                      lat == place.location?.latitude ,
                      lon == place.location?.longitude
                else{
                    continue
                }
                if placeData == nil {
                    placeData = data
                    break
                }
            }
            completion(placeData)
        }
    }
    
    
}
// MARK: - LocationDelegate
extension SearchViewController : LocationDelegate{
    func locationGotUser(With location: CLLocation) {
        self.userLocation = location
    }
    func locationDidSet(FirstLocation location: CLLocation) {
        self.moveRegion(coordinate: location.coordinate, degree: 0.001)
    }
    
    /// 移動到特定座標並放大該區域
    /// - Parameters:
    ///   - coordinate: 要移動到的座標
    ///   - degree: 放大縮小的範圍
    func moveRegion(coordinate : CLLocationCoordinate2D , degree :
        Double){
        var region = MKCoordinateRegion()
        region.center = coordinate
        region.span = MKCoordinateSpanMake(degree, degree)
        self.mapView.setRegion(region, animated: true)
    }
}
// MARK: - SearchDelegate
extension SearchViewController : SearchDelegate{
    func serchViewDidBegainEditing(_ sender: UITextField, radius: Float) {
    }
    func searchViewDidEndEditing(_ sender: UITextField, radius: Float) {
    }
    func serchViewChangedSearchRegion(With radius: Float) {
        
    }
    func searchViewStartSearch(_ sender: UITextField, radius: Float) {
        guard let query = sender.text ,
              query.count > 0
        else {
            return
        }
        // 開始 waitingView
        self.waitingView.showing(true)
        
        // 清空 places 與 lon
        self.places.removeAll()
        self.annotations.removeAll()
        self.mapView.removeAnnotations(self.mapView.annotations)
        
        self.searchPlaces(With: query, Location: self.userLocation.coordinate, Radius:  Double(radius), NextPage: search.nextPageToken)
    }
    
    
    /// 為了可以重複呼叫達到 while 的效果所以用 巢狀迴圈
    func searchPlaces(With query : String ,
                      Location location : CLLocationCoordinate2D ,
                      Radius radius: Double ,
                      NextPage nextToken : String?){
        // 開始搜尋
        search.searchPlaces(With: query, Location: location, Radius: radius, NextPage: nextToken) { (places, errorMsg) in
            if let errorMsg = errorMsg{
                print("search Error Message : \(errorMsg)")
                // 跳出 Alert
                self.showErrorAlert(title: "搜尋錯誤", message: "無法搜尋到結果，請更換關鍵字與搜尋範圍，或過段時間再次搜尋!")
                return
            }
            guard let places = places else{
                // 跳出 Alert
                self.showErrorAlert(title: "搜尋錯誤", message: "無法搜尋到結果，請更換關鍵字與搜尋範圍，或過段時間再次搜尋!")
                return
            }
            for place in places{
                guard let location = place.location else{
                    print("location is nil")
                    continue
                }
                self.places.append(place)
                DispatchQueue.main.async {
                    // 關閉 WaitingView
                    self.waitingView.showing(false)
                    // 新增一個 大頭針
                    self.mapAddNewAnnotation(coordinate: location, title: place.name, subTitle: place.address)
                }
            }
            // 若 回傳結果 為0 跳出警告視窗
            if self.places.count == 0{
                self.showErrorAlert(title: "搜尋錯誤", message: "無法搜尋到結果，請更換關鍵字與搜尋範圍，或過段時間再次搜尋!")
                return
            }
            // 判斷 next token 是否為 nil
            guard self.search.nextPageToken != nil else{
                print("search.nextPageToken is nil")
                return
            }
            // 若不是再次執行自己
            self.searchPlaces(With: query, Location: location, Radius: radius, NextPage: self.search.nextPageToken)
            
        }
    }
    
    
    /// 顯示錯誤 Alert
    ///
    /// - Parameters:
    ///   - title: 錯誤 title
    ///   - message: 錯誤 訊息
    func showErrorAlert(title : String? , message : String?){
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let cancel = UIAlertAction(title: "確定", style: .cancel, handler: nil)
        alert.addAction(cancel)
        DispatchQueue.main.async {
            self.present(alert, animated: true, completion: nil)
            self.waitingView.showing(false)
        }
    }
}
// MARK: - MKMapViewDelegate
extension SearchViewController : MKMapViewDelegate{
    /// 新增新的大頭針到 map 上
    /// - Parameters:
    ///   - coordinate: 輸入包含經緯度的座標，用CLLocationCoordinate2D
    ///   - note: 輸入的註解
    func mapAddNewAnnotation(coordinate:CLLocationCoordinate2D, title:String? , subTitle : String?){
        let pinAnnotation = MKPointAnnotation()
        pinAnnotation.coordinate = coordinate
        pinAnnotation.title = title
        pinAnnotation.subtitle = subTitle
        DispatchQueue.main.async {
            // 新增座標點
            self.mapView.addAnnotation(pinAnnotation)
            // 記錄起 annotation
            self.annotations.append(pinAnnotation)
        }
    }
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation.isEqual(mapView.userLocation) {
            return nil
        }
        
        let include =  self.annotations.contains { (element) -> Bool in
            if element.title == annotation.title &&
                element.coordinate.longitude == annotation.coordinate.longitude &&
                element.coordinate.latitude == element.coordinate.latitude {
                return true
            }
            return false
        }
        if !include {
            print("not include")
            return nil
        }
        let index = self.annotations.index { (element) -> Bool in
            if element.title == annotation.title &&
                element.coordinate.longitude == annotation.coordinate.longitude &&
                element.coordinate.latitude == element.coordinate.latitude {
                return true
            }
            return false
        }
        guard let annIndex = index else {
            print("annIndex is nil")
            return nil
        }
        let place = self.places[annIndex]
        
        var annotationID : String = "\(annIndex)"
        if let placeID = place.placeID{
            annotationID = placeID
        }
        var colorPin : MKPinAnnotationView!
        if let pin =  mapView.dequeueReusableAnnotationView(withIdentifier: annotationID) as? MKPinAnnotationView {
            pin.annotation = annotation
            colorPin = pin
        }else{
            colorPin = MKPinAnnotationView.init(annotation: annotation, reuseIdentifier: annotationID)
        }
        colorPin.canShowCallout = true
        colorPin.animatesDrop = true
        colorPin.pinTintColor = UIColor.blue
        colorPin.rightCalloutAccessoryView = UIButton(type: UIButtonType.detailDisclosure)
        return colorPin
    }
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        guard let annotation = view.annotation else {
            return
        }
        let include =  self.annotations.contains { (element) -> Bool in
            if element.title == annotation.title &&
                element.coordinate.longitude == annotation.coordinate.longitude &&
                element.coordinate.latitude == element.coordinate.latitude {
                return true
            }
            return false
        }
        if !include {
            print("not include")
            return
        }
        let index = self.annotations.index { (element) -> Bool in
            if element.title == annotation.title &&
                element.coordinate.longitude == annotation.coordinate.longitude &&
                element.coordinate.latitude == element.coordinate.latitude {
                return true
            }
            return false
        }
        guard let annIndex = index else {
            print("annIndex is nil")
            return
        }
        let place = self.places[annIndex]
        
        // 搜尋是否有 data ， 若有則顯示 data
        self.searchData(With: place) { (data) in
            guard let data = data else{
                self.showDataVC(place: place, data: nil)
                return
            }
            self.showDataVC(place: nil, data: data)
        }
        
    }
}
