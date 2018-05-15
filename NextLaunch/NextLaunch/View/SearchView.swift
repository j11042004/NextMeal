//
//  SearchView.swift
//  NextLaunch
//
//  Created by Uran on 2018/5/8.
//  Copyright © 2018年 Uran. All rights reserved.
//

import UIKit
@objc protocol SearchDelegate : NSObjectProtocol {
    /// sarchView 開始輸入文字
    ///
    /// - Parameters:
    ///   - sender: 編輯進入的 UITextField
    ///   - radius: 指定的半徑範圍
    @objc optional func serchViewDidBegainEditing(_ sender : UITextField , radius : Float)
    /// sarchView 輸入文字結束時
    ///
    /// - Parameters:
    ///   - sender: 編輯進入的 UITextField
    ///   - radius: 指定的半徑範圍
    @objc optional func searchViewDidEndEditing(_ sender : UITextField, radius : Float)
    /// sarchView 開始搜尋時
    ///
    /// - Parameters:
    ///   - sender: 編輯進入的 UITextField
    ///   - radius: 指定的半徑範圍
    @objc optional func searchViewStartSearch(_ sender : UITextField , radius : Float)
    
    /// 更換搜尋範圍時會呼叫
    ///
    /// - Parameter radius: 搜尋的範圍
    @objc optional func serchViewChangedSearchRegion(With radius : Float)
}
class SearchView: UIView {
    
    private var view : UIView!
    /// 搜尋的 textField
    @IBOutlet private weak var searchTextField: UITextField!
    @IBOutlet private weak var cancelButton: UIButton!
    @IBOutlet private weak var selectButton: UIButton!
    /// 控制 select button x 位置的 constrain
    @IBOutlet private weak var selectLeftConstraint: NSLayoutConstraint!
    /// 控制 cancel button x 位置的 constrain
    @IBOutlet private weak var cancelRightConstraint: NSLayoutConstraint!
    /// 顯示 keyboard 時的 tool bar
    @IBOutlet private var keyboardToolBar: UIToolbar!
    @IBOutlet private weak var regionLabel: UILabel!
    @IBOutlet private weak var regionSlider: UISlider!
    
    
    /// 輸入框的文字
    public var text : String? {
        let text = self.searchTextField.text
        return text
    }
    /// 範圍距離
    public var radiusRange : Float! {
        let radius = self.regionSlider.value
        return radius
    }
    
    
    public var delegate : SearchDelegate?
    
    convenience init(){
        self.init(frame: CGRect.zero)
    }
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.customerInit()
    }
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.customerInit()
    }
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    func customerInit(){
        view = self.loadViewfromNib()
        // 設定 Textfield 顯示 keyboard 上的一塊區域
        self.searchTextField.inputAccessoryView = keyboardToolBar
        // 設定 Textfield 顯示 keyboard 上的 return 按鈕改成 search
        self.searchTextField.returnKeyType = UIReturnKeyType.search
        // 先預設 兩邊的 button 都隱藏
        self.selectButton.isHidden = true
        self.cancelButton.isHidden = true
        self.selectLeftConstraint.constant =  -self.selectButton.frame.width
        self.cancelRightConstraint.constant =  -self.cancelButton.frame.width
        // 關閉搜尋畫面
        self.presentTheSearch(false)
        self.addSubview(view)
        self.searchTextField.delegate = self
    }
    
    func loadViewfromNib() -> UIView {
        let xibStr = String(describing: type(of: self))
        let bundle = Bundle(for: type(of: self))
        let nib = UINib(nibName: xibStr, bundle: bundle)
        let view = nib.instantiate(withOwner: self, options: nil)[0] as! UIView
        view.frame = self.bounds
        return view
    }
    
    /// 決定什麼時候要顯示 cancel button
    ///
    /// - Parameter show: 是否顯示
    private func presentTheSearch(_ show : Bool){
        self.selectLeftConstraint.constant = show ? 0 : -self.selectButton.frame.width
        self.cancelRightConstraint.constant = show ? 0 : -self.cancelButton.frame.width
        if self.selectButton.alpha == 0{
            self.selectButton.isHidden = false
            self.cancelButton.isHidden = false
        }
        // 顯示與消失 cancel Button 的動畫
        UIView.animate(withDuration: 0.5, animations: {
            self.layoutIfNeeded()
            self.selectButton.alpha = show ? 1 : 0
            self.cancelButton.alpha = show ? 1 : 0
        }){ (_) in
            self.selectButton.isHidden = !show
            self.cancelButton.isHidden = !show
        }
    }
    
    @IBAction func cancelInsert(_ sender: UIButton) {
        self.endEditing(true)
        self.presentTheSearch(false)
    }
    @IBAction func chooseSelete(_ sender: UIButton) {
        
    }
    
    @IBAction func insertRegionAlert(_ sender: UIButton) {
        let alert = UIAlertController(title: "請輸入範圍", message: "範圍最小為 500 公尺，最大為 10000 公尺", preferredStyle: .alert)
        alert.addTextField { (textfield) in
            // 設定鍵盤的種類
            textfield.keyboardType = .numbersAndPunctuation
        }
        let decide = UIAlertAction(title: "確定", style: .default) { (_) in
            // 判斷輸入框的文字是否可轉成 Float ，並且 > 最小值
            guard let text = alert.textFields?.first?.text,
                let value = Float(text),
                value > self.regionSlider.minimumValue
            else{
                self.changeRadiusValue(value: self.regionSlider.minimumValue)
                return
            }
            // 若超過最大值就設為最大值
            if value > self.regionSlider.maximumValue {
                self.changeRadiusValue(value: self.regionSlider.maximumValue)
                return
            }
            self.changeRadiusValue(value: value)

        }
        alert.addAction(decide)
        
        DispatchQueue.main.async {
           UIApplication.shared.keyWindow?.rootViewController?.present(alert, animated: true, completion: nil)
        }
    }
    
    @IBAction func changeSliderValue(_ sender: UISlider) {
        self.changeRadiusValue(value: sender.value)
    }
    /// 更換距離
    private func changeRadiusValue(value : Float){
        self.regionSlider.value = value
        self.regionLabel.text = "\(value)"
        self.delegate?.serchViewChangedSearchRegion?(With: value)
    }
}

extension SearchView : UITextFieldDelegate{
    func textFieldDidBeginEditing(_ textField: UITextField) {
        self.presentTheSearch(true)
        // func 後面的 ? 是判斷是否有實作 option func 若有就執行，若無就不動作
        delegate?.serchViewDidBegainEditing?(textField, radius: self.regionSlider.value)
    }
    func textFieldDidEndEditing(_ textField: UITextField) {
        self.endEditing(true)
        self.presentTheSearch(false)
        // func 後面的 ? 是判斷是否有實作 option func 若有就執行，若無就不動作
        delegate?.searchViewDidEndEditing?(textField , radius: self.regionSlider.value)
    }
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.endEditing(true)
        self.presentTheSearch(false)
        // func 後面的 ? 是判斷是否有實作 option func 若有就執行，若無就不動作
        self.delegate?.searchViewStartSearch?(self.searchTextField, radius: self.regionSlider.value)
        return true
    }
}
