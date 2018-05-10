//
//  AddDataViewController.swift
//  NextLaunch
//
//  Created by Uran on 2018/3/15.
//  Copyright © 2018年 Uran. All rights reserved.
//

import UIKit
import MapKit

class DataViewController: UIViewController {
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var mapViewHConstraint: NSLayoutConstraint!
    @IBOutlet weak var leadBtn: UIButton!
    
    @IBOutlet weak var nowLocationBtn: UIButton!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var infoView: UIView!
    @IBOutlet weak var goalTextField: UITextField!
    @IBOutlet weak var addressTextView: UITextView!
    
    @IBOutlet weak var noteTextView: UITextView!
    @IBOutlet weak var imageView: UIImageView!
    
    @IBOutlet weak var barView: UIView!
    @IBOutlet weak var imgLabel: UILabel!
    
    @IBOutlet weak var decideAddressBtn: UIButton!
    
    public var data : SqlData?
    public var goalPlace : ResultPlace?
    private let database = DBManager.shared
    private let imgPicker = ImagePickerManager.shared
    private let addressManager = AddressManager.shared
    private let notification = NotificationCenter.default
    
    var location : Location!
    var userLocation : CLLocation?
    var firtLocation : CLLocation?
    var lastLocation : CLLocation?
    var goalLocation : CLLocation?
    var infoViewSize : CGSize!
    var constraintHeight : CGFloat = 0
    
    var changeBool = false
    var touchBeganPoint : CGPoint?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        location = Location.shardInstrance
        location.delelgate = self
        location.requestLocationAllowed()
        
        // 簽訂 Delegate
        self.imgPicker.imagePickerDelegate = self
        self.mapView.delegate = self
        self.goalTextField.delegate = self
        self.addressTextView.delegate = self
        self.noteTextView.delegate = self
        
        // 現在位置Button 進行圓角化
        self.nowLocationBtn.layer.masksToBounds = true
        self.nowLocationBtn.layer.cornerRadius = self.nowLocationBtn.frame.width/2
        
        // 讓 imageView 可以被按
        let imgViewGesture = UITapGestureRecognizer(target: self, action: #selector(DataViewController.imgTapGesture(_:)))
        self.imageView.isUserInteractionEnabled = true
        self.imageView.addGestureRecognizer(imgViewGesture)
        
        // mapview 新增點擊事件
        let mapviewTap = UITapGestureRecognizer.init(target: self, action: #selector(mapviewTapAdd(_:)))
        self.mapView.addGestureRecognizer(mapviewTap)
        
        // 為 addressTextView 加入邊線
        self.addressTextView.layer.borderWidth = 0.2
        self.addressTextView.layer.borderColor = UIColor.lightGray.cgColor
        self.addressTextView.layer.cornerRadius = 5
        
        // 當鍵盤顯示或消失時會接收通知
        self.notification.addObserver(self, selector: #selector(self.showKeyboardAction(_:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        self.notification.addObserver(self, selector: #selector(self.hideKeyboardAction(_:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        
        
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // 設定 BarView 的 border
        self.barView.layer.borderColor = UIColor.lightGray.cgColor
        self.barView.layer.borderWidth = 0.4
        self.barView.layer.cornerRadius = 5
        self.navigationController?.navigationBar.isHidden = true
        
        // 將取得的 Data 資料或是 Place 放到 UI 上
        if let _ = self.data{
            self.setDataInfo()
        }else if let _ = self.goalPlace{
            self.setPlaceInfo()
        }
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // 設定 ScrollView 的大小
        self.infoViewSize = self.infoView.frame.size
        self.scrollView.contentSize = CGSize(width: self.infoViewSize.width, height: self.infoViewSize.height + 40)
        // 縮小到使用者的位置
        self.moveRegion(coordinate: self.mapView.userLocation.coordinate)
    }
    
    // MARK:- Normal Function
    /// 將取得的Data 資料放到 UI 上
    func setDataInfo(){
        self.goalTextField.text = self.data?.name
        self.addressTextView.text = self.data?.address
        
        if self.goalTextField.text?.count == 0{
            // 用程式碼觸發 decideAddressBtn 的 方法，讓使用者一開始不行在 map 上新增 目的地
            self.decideAddressBtn.sendActions(for: .touchUpInside)
        }
        self.noteTextView.text = self.data?.note
        // 取得 圖片
        if let data = self.data?.imageData{
            let image = UIImage(data: data)
            self.imageView.image = image
            if image != nil {
                self.imgLabel.isHidden = true
            }
        }
        // 取得座標
        guard let latitude = self.data?.latitude  else {
            // 若無經緯度就隱藏導航按鈕
            self.leadBtn.isHidden = true
            return
        }
        guard let longitude = self.data?.longitude  else {
            // 若無經緯度就隱藏導航按鈕
            self.leadBtn.isHidden = true
            return
        }
        //顯示導航按鈕
        self.leadBtn.isHidden = false
        // 曲的座標
        let coordinate = CLLocationCoordinate2D.init(latitude: latitude, longitude: longitude)
        // 新增大頭釘到map 上
        self.mapAddNewAnnotation(coordinate: coordinate, title: self.data?.name, removeOld: true)
    }
    
    /// 將取得的 Place 資料放到 UI 上
    func setPlaceInfo(){
        self.goalTextField.text = self.goalPlace?.name
        if self.goalTextField.text?.count == 0{
            // 用程式碼觸發 decideAddressBtn 的 方法
            self.decideAddressBtn.sendActions(for: .touchUpInside)
        }
        self.addressTextView.text = self.goalPlace?.address
        // 放入圖片
        if let image = self.goalPlace?.stickerPhoto {
            self.imageView.image = image
        }
        // 放入座標
        guard let coordinate = goalPlace?.location else{
            self.leadBtn.isHidden = true
            return
        }
        self.leadBtn.isHidden = false
        
        // 新增大頭釘到map 上
        self.mapAddNewAnnotation(coordinate: coordinate, title: self.data?.name, removeOld: true)
    }
    
    
    /// 關閉 ViewController
    func dismissVC(){
        // 過場動畫效果
        let transition = CATransition()
        transition.duration = 0.3
        transition.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionLinear)
        transition.type = kCATransitionReveal
        transition.subtype = kCATransitionFromLeft
        
        if self.navigationController != nil{
            self.navigationController?.view.window?.layer.add(transition, forKey: nil)
            self.navigationController?.popViewController(animated: true)
        }else{
            self.view.window?.layer.add(transition, forKey: nil)
            self.dismiss(animated: false, completion: nil)
        }
    }
    /// 地址轉座標加到 mapview 上
    func addAnnotationByAddress(_ address : String){
        self.addressManager.addressToCoordinate(With: address, mapView: self.mapView, completion: { (success, error, coordinate) in
            if success {
                guard let coordinate = coordinate else{
                    NSLog("coordinates is nil")
                    return
                }
                // 新增大頭針
                self.mapAddNewAnnotation(coordinate: coordinate, title: self.goalTextField.text, removeOld: true)
                self.moveRegion(coordinate: coordinate)
            }
        })
    }
    
    
    // MARK:- Alert Function
    /// 顯示確定 Alert
    func showSureAlert(title : String? , message: String? , cancelTitle:String?){
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
        let cancel = UIAlertAction(title: cancelTitle, style: .cancel, handler: nil)
        alert.addAction(cancel)
        self.present(alert, animated: true) {
            self.view.endEditing(true)
        }
    }
    
    /// 顯示跳轉到 設定的 Alert
    func showSetAlert(){
        let alert = UIAlertController(title: nil, message: "請問是否要開啟設定，前往權限要求畫面，將權限改成允許使用？", preferredStyle: .alert)
        let cancel = UIAlertAction.init(title: "取消", style: .cancel) { (action) in
            DispatchQueue.main.async {
                self.dismissVC()
            }
        }
        let ok = UIAlertAction.init(title: "前往", style: .default) { (action) in
            if let setUrl = URL(string: UIApplicationOpenSettingsURLString){
                UIApplication.shared.open(setUrl, options: [String : Any](), completionHandler: nil)
            }
        }
        alert.addAction(cancel)
        alert.addAction(ok)
        self.present(alert, animated: true, completion: nil)
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
// MARK:- IBAction
extension DataViewController {
    // MARK:- UIAction Function
    /// 儲存資料，若已有資料就更新，否則就新增
    @IBAction func saveDataAction(_ sender: UIButton) {
        self.view.endEditing(true)
        var name : String!
        // 判斷是否有設定目的地名
        if let goalName = self.goalTextField.text ,
            goalName.count > 0
        {
            name = goalName
        }else{
            name = "未命名餐廳"
        }
        
        let note = self.noteTextView.text
        let address = self.addressTextView.text
        let image = self.imageView.image
        var latitude : Double?
        var longtiude : Double?
        // 儲存 goalLocation 裡的經緯度
        if let location = self.goalLocation{
            let coordinate = location.coordinate
            latitude = coordinate.latitude
            longtiude = coordinate.longitude
            // 若無經緯度就隱藏導航按鈕
            self.leadBtn.isHidden = false
        }else{
            latitude = nil
            longtiude = nil
            // 若無經緯度就隱藏導航按鈕
            self.leadBtn.isHidden = true
        }
        // 若有資料就更新，否則就新增，成功或失敗會跳出Alert 通知
        if let savedData = self.data {
            savedData.name = name
            savedData.latitude = latitude
            savedData.longitude = longtiude
            savedData.note = note
            savedData.address = address
            if let image = image{
                let data = UIImagePNGRepresentation(image)
                savedData.imageData = data
            }else{
                savedData.imageData = nil
            }
            // 更新 Data
            if database.updateData(savedData) {
                self.showSureAlert(title: nil, message: "已更新成功", cancelTitle: "確定")
                self.data = savedData
                self.setDataInfo()
                
            }else{
                self.showSureAlert(title: nil, message: "更新失敗", cancelTitle: "確定")
            }
        }else{
            let savedData = SqlData(id: nil, name: name, latitude: latitude, longitude: longtiude, note: note, address: address, image: image)
            // 新增 Data
            if database.insertData(savedData) {
                self.showSureAlert(title: nil, message: "已儲存成功", cancelTitle: "確定")
                // 將VC 的 data 設為這建立的 data，避免之後建立後又再次跳到這
                self.data = savedData
                self.setDataInfo()
            }else{
                self.showSureAlert(title: nil, message: "儲存失敗", cancelTitle: "確定")
            }
        }
    }
    /// 移動到現在位置
    @IBAction func nowLocationAction(_ sender: UIButton) {
        self.view.endEditing(true)
        self.moveRegion(coordinate: self.mapView.userLocation.coordinate)
    }
    /// 移動到目的位置
    @IBAction func moveToGoalLocation(_ sender: UIButton) {
        self.view.endEditing(true)
        guard let coordinate = self.goalLocation?.coordinate else{
            return
        }
        self.moveRegion(coordinate: coordinate)
    }
    
    
    /// 回上一頁 Button
    @IBAction func backBtnAction(_ sender: UIButton) {
        self.dismissVC()
    }
    
    /// 導航按鈕
    @IBAction func leadBtnAction(_ sender: UIButton) {
        self.view.endEditing(true)
        self.leadMapNavigation()
    }
    /// 決定地點
    @IBAction func DecideAddressAction(_ sender: UIButton) {
        self.changeBool = !self.changeBool
        if self.changeBool {
            self.decideAddressBtn.setTitle("確定", for: .normal)
            
            self.addressTextView.isEditable = true
            self.addressTextView.isSelectable = true
            return
        }
        self.decideAddressBtn.setTitle("更換", for: .normal)
        self.addressTextView.isEditable = false
        self.addressTextView.isSelectable = false
        if self.addressTextView.text != nil {
            self.leadBtn.isHidden = false
        }
        
    }
    
    /// 在 地圖上用點擊新增 Annotation
    @objc func mapviewTapAdd(_ sender : UITapGestureRecognizer){
        self.view.endEditing(true)
        // 若不允許更換就跳出
        if !self.changeBool {
            return
        }
        let tapPoint = sender.location(in: self.mapView)
// 將點擊在UIView上的位置換成座標
        let coordinate = self.mapView.convert(tapPoint, toCoordinateFrom: self.mapView)
        // 新增大頭釘到map 上
        self.mapAddNewAnnotation(coordinate: coordinate, title: self.goalTextField.text, removeOld: true)
    }
    
    
    @objc func showKeyboardAction (_ sender : Notification){
        self.constraintHeight = self.mapViewHConstraint.constant
        if self.mapViewHConstraint.constant <= 150 {
            return
        }
        self.mapViewHConstraint.constant = 150
        UIView.animate(withDuration: 0.3) {
            // 跑這行才會執行 Layout 的動畫
            self.view.layoutIfNeeded()
        }
    }
    @objc func hideKeyboardAction (_ sender : Notification){
        if self.constraintHeight <= 150 {
            return
        }
        self.mapViewHConstraint.constant = self.constraintHeight
        UIView.animate(withDuration: 0.3){
            // 跑這行才會執行 Layout 的動畫
            self.view.layoutIfNeeded()
        }
    }
    
}
// MARK:- MKMapViewDelegate
extension DataViewController : MKMapViewDelegate{
    /// 新增新的大頭針到 map 上
    ///
    /// - Parameters:
    ///   - coordinate: 輸入包含經緯度的座標，用CLLocationCoordinate2D
    ///   - note: 輸入的註解
    ///   - removeOld :是否移除除了MyLocation外，其他的Annotation
    func mapAddNewAnnotation(coordinate:CLLocationCoordinate2D, title:String? , removeOld :Bool){
        let pinAnnotation = MKPointAnnotation()
        pinAnnotation.coordinate = coordinate
        pinAnnotation.title = title
        DispatchQueue.main.async {
            if removeOld {
                self.mapView.removeAnnotations(self.mapView.annotations)
            }
            // 新增座標點
            self.mapView.addAnnotation(pinAnnotation)
        }
        // 判斷地址欄是否有 地址，若有就不轉換並加入
        if let address = self.addressTextView.text ,
            address.count > 0 {
            print("有值")
        }else{
            self.addressManager.coordinateToAddress(With: coordinate) { (success, error, address) in
                if success{
                    self.addressTextView.text = address
                }
            }
        }
        
        // 在這更新 goalLocation
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        self.goalLocation = location
    }
    // 傳回 mapview 上大頭針的樣式
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation.isEqual(mapView.userLocation) {
            return nil
        }
        let annotationID = "meal"
        
        // 設定 ResultPin 上的 title 與其他細項
        let resultAnnotation = MKPointAnnotation()
        resultAnnotation.coordinate = annotation.coordinate
        resultAnnotation.title = self.goalTextField.text
        // 建立 ResultPin
        var resultPin = mapView.dequeueReusableAnnotationView(withIdentifier: annotationID)
        if resultPin == nil {
            resultPin = MKAnnotationView(annotation: resultAnnotation, reuseIdentifier: annotationID)
        }else{
            resultPin?.annotation = resultAnnotation
        }
        // 設定 resultPin 會不會顯示輸入的字
        resultPin?.canShowCallout = true
        // 設定 resultPin 上的 圖片
        let image = UIImage(named: "meal.png")
        resultPin?.image = image
        let imageView = UIImageView(image: image)
        resultPin?.leftCalloutAccessoryView = imageView
        // 可被移動
        resultPin?.isDraggable = true
        return resultPin
    }
    
}
// MARK:- LocationDelegate
extension DataViewController : LocationDelegate{
    func locationGotUser(With location: CLLocation) {
        self.userLocation = location
    }
    func locationDidSet(FirstLocation location: CLLocation) {
        self.firtLocation = location
        // 第一次移動到目標位置
        self.moveRegion(coordinate: location.coordinate)
    }
    /// 移動到特定座標並放大該區域
    func moveRegion(coordinate : CLLocationCoordinate2D){
        var region = MKCoordinateRegion()
        region.center = coordinate
        region.span = MKCoordinateSpanMake(0.001, 0.001)
        self.mapView.setRegion(region, animated: true)
    }
    /// 導航至目的地
    func leadMapNavigation(){
        // 判斷現在所在位置是否為 nil
        guard let _ = self.userLocation?.coordinate else {
            self.showSureAlert(title: "Warning", message: "請檢查是否有 Gps 訊號，請稍後再行使用導航功能", cancelTitle: "確定")
            return
        }
        // 判斷目的地經緯度是否為 nil
        guard let lat = self.goalLocation?.coordinate.latitude else{
            self.showSureAlert(title: "Warning", message: "請檢查是否有 Gps 訊號，或是重新指定目的地，請稍後再行使用導航功能", cancelTitle: "確定")
            return
        }
        guard let lon = self.goalLocation?.coordinate.longitude else {
            self.showSureAlert(title: "Warning", message: "請檢查是否有 Gps 訊號，或是重新指定目的地，請稍後再行使用導航功能", cancelTitle: "確定")
            return
        }
        // 目的地座標設定
        let goalCoordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
        let regionDistance:CLLocationDistance = 1000;
        let regionSpan = MKCoordinateRegionMakeWithDistance(goalCoordinate, regionDistance, regionDistance)
        
        let options = [MKLaunchOptionsMapCenterKey: NSValue(mkCoordinate: regionSpan.center),
                       MKLaunchOptionsMapSpanKey: NSValue(mkCoordinateSpan: regionSpan.span)]
        // 目的地大頭針
        let placemark = MKPlacemark(coordinate: goalCoordinate)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = self.goalTextField.text
        
        // 詢問是否要跳轉到 Apple map
        let alert = UIAlertController(title: nil, message: "是否要開啟 Apple Map 導航至目的地", preferredStyle: .alert)
        let cancel = UIAlertAction(title: "取消", style: .cancel, handler: nil)
        let open = UIAlertAction(title: "開啟", style: .default) { (action) in
            // 開啟地圖
            mapItem.openInMaps(launchOptions: options)
        }
        alert.addAction(cancel)
        alert.addAction(open)
        self.present(alert, animated: true, completion: nil)
    }
    
}
// MARK:- ImagePickerManagerDelegate
extension DataViewController:ImagePickerManagerDelegate{
    
    @objc func imgTapGesture(_ sender:UIGestureRecognizer){
        self.imgPicker.showImageAlert(dataName: self.goalTextField.text, dataNote: self.noteTextView.text )
    }
    func imagePickerGetImage(image: UIImage?, dataNote: String?, dataName: String?) {
        self.imageView.image = image
        if image != nil {
            self.imgLabel.isHidden = true
        }else{
            self.imgLabel.isHidden = false
        }
        self.goalTextField.text = dataName
        self.noteTextView.text = dataNote
    }
}

// MARK:- UITextFieldDelegate , UITextViewDelegate
extension DataViewController : UITextFieldDelegate , UITextViewDelegate{
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return false
    }
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if(text == "\n") {
            textView.resignFirstResponder()
            // 若是 addressTextView，就將Address 改成 座標
            if textView === self.addressTextView && self.changeBool {
                self.addAnnotationByAddress(self.addressTextView.text)
            }
            return false
        }
        
        return true
    }
}
// MARK:- Touch 相關
extension DataViewController {
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
        self.scrollView.endEditing(true)
        self.infoView.endEditing(true)
        self.mapView.endEditing(true)
        
        let firstTouch = touches.first
        guard let firstPoint = firstTouch?.location(in: self.view) else{
            return
        }
        let touchView = self.view.hitTest(firstPoint, with: event)
        if touchView === self.barView {
            self.touchBeganPoint = firstPoint
        }
    }
    // 更換地圖畫面的高度
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)
        if self.touchBeganPoint == nil {
            return
        }
        let firstTouch = touches.first
        guard let previousPoint = firstTouch?.previousLocation(in: self.view) else{
            return
        }
        guard let nowPoint = firstTouch?.location(in: self.view) else{
            return
        }
        
        // 變更 MapView 高度
        let yRange = nowPoint.y - previousPoint.y
        let nowMapHeight = self.mapViewHConstraint.constant
        self.mapViewHConstraint.constant = nowMapHeight + yRange
        if self.mapViewHConstraint.constant >= self.view.frame.height*2/3 {
            self.mapViewHConstraint.constant = self.view.frame.height*2/3
        }
        if self.mapViewHConstraint.constant <= self.view.frame.height*1/5{
            self.mapViewHConstraint.constant = self.view.frame.height*1/5
        }
        self.constraintHeight = self.mapViewHConstraint.constant
        self.updateViewConstraints()

    }
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.touchBeganPoint = nil
    }
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.touchBeganPoint = nil
    }
}
