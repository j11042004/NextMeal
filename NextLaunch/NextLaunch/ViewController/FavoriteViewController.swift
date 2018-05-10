//
//  ViewController.swift
//  NextLaunch
//
//  Created by Uran on 2018/3/14.
//  Copyright © 2018年 Uran. All rights reserved.
//

import UIKit
import CoreLocation
class FavoriteViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchItem: UIBarButtonItem!
    @IBOutlet weak var diceItem: UIBarButtonItem!
    @IBOutlet weak var addItem: UIBarButtonItem!
    
    
    var closeItem : UIBarButtonItem!
    var rightBars = [UIBarButtonItem]()
    var leftBars = [UIBarButtonItem]()
    
    let cellID = "Cell"
    let dataCellID = "DataCell"
    var sqlDatas : [SqlData]!
    let database = DBManager.shared
    let address = AddressManager.shared
    let searchBar : UISearchBar = UISearchBar()
    private let searchbarWidth = UIScreen.main.bounds.width * 2/3
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let dataNib = UINib.init(nibName: "DataTableCell", bundle: Bundle(for: type(of: self)))
        self.tableView.register(dataNib, forCellReuseIdentifier: dataCellID)
        
        // 設定 rightBars
        self.rightBars = [self.diceItem , self.addItem , self.searchItem]
        
        // 設定 LeftBarItems
        // 新增一個關閉 item 關閉 searchbarItem
        self.closeItem = UIBarButtonItem(title: "Close", style: .done, target: self, action: #selector(closeItemAction(_:)))
        // 設定 SearchBar
        self.searchBar.frame = CGRect(x: 0, y: 0, width: 0, height: 20)
        self.searchBar.delegate = self
        // 將 searchbar 加到 left navigation bar 上
        let searchbarItem = UIBarButtonItem(customView: self.searchBar)
        self.leftBars = [searchbarItem ,self.closeItem , self.diceItem]
        // 是否顯示 searchbarItem
        self.showNavSearchBar(false)
        
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // 判斷是否有 leftBarButtonItems
        if self.navigationItem.leftBarButtonItems != nil {
            self.searchResult(self.searchBar.text)
        }else{
            self.sqlDatas = database.searchAllData()
            self.tableView.reloadData()
        }
        // 顯示 navigationBar
        self.navigationController?.navigationBar.isHidden = false
        
        // sqlData 去搜尋全部的資料
        self.sqlDatas = database.searchAllData()
        self.tableView.reloadData()
    }
    ///MARK:- IBAction
    @IBAction func addNewData(_ sender: UIBarButtonItem) {
        self.showDataVC(data: nil)
    }
    @IBAction func launchSelectionAction(_ sender: UIBarButtonItem) {
        if self.sqlDatas.count == 0 {
            return
        }
        let num : Int = Int(arc4random_uniform(UInt32(self.sqlDatas.count)) )
        self.showDataVC(data: self.sqlDatas[num])
    }
    @IBAction func searchItemAction(_ sender: UIBarButtonItem) {
        self.showNavSearchBar(true)
    }
    
    /// 收起 SearchBar
    @objc func closeItemAction(_ sender: UIBarButtonItem){
        self.showNavSearchBar(false)
        searchBar.text = nil
        searchBar.endEditing(true)
        // sqlData 去搜尋全部的資料
        self.sqlDatas = database.searchAllData()
        self.tableView.reloadData()
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    /// 決定是否要顯示 SearchBar
    func showNavSearchBar(_ show : Bool){
        if show {
            UIView.animate(withDuration: 0.3, animations: {
                self.navigationItem.rightBarButtonItems = nil
                self.navigationItem.leftBarButtonItems = self.leftBars
                self.searchBar.frame = CGRect(x: 0, y: 0, width: self.searchbarWidth, height: 20)
            })
            return
        }
        self.navigationItem.leftBarButtonItems = nil
        self.navigationItem.rightBarButtonItems = self.rightBars
        self.searchBar.frame = CGRect(x: 0, y: 0, width: 0, height: 20)
    }
    /// 顯示 VC 顯示對應的 Data
    func showDataVC(data : SqlData?) {
        let bundele : Bundle = Bundle(for: DataViewController.self)
        let nextVC = DataViewController(nibName: "DataViewController", bundle: bundele)
        nextVC.data = data
        
        // 轉場動畫效果
        let transition = CATransition()
        transition.duration = 0.3
        transition.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionLinear)
        transition.type = kCATransitionReveal
        transition.subtype = kCATransitionFromRight
        self.view.window?.layer.add(transition, forKey: nil)
        self.present(nextVC, animated: false, completion: nil)
    }
}

extension FavoriteViewController : UITableViewDelegate,UITableViewDataSource{
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sqlDatas.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: self.dataCellID, for: indexPath)
        guard let dataCell = cell as? DataTableCell else {
            cell.textLabel?.text = "\(indexPath.row)"
            return cell
        }
        let data = sqlDatas[indexPath.row]
        // 判斷 座標是否存在
        if let lat = data.latitude ,
            let lon = data.longitude
        {
            let coordinate = CLLocationCoordinate2D.init(latitude: lat, longitude: lon)
            // 將座標轉成地址
            address.coordinateToAddress(With: coordinate) { (success, error, addressStr) in
                dataCell.noteLabel.text = addressStr
            }
        }
        
        dataCell.storeLabel.text = data.name
        dataCell.noteLabel.numberOfLines = 0
        dataCell.noteLabel.sizeToFit()
        return dataCell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let data = sqlDatas[indexPath.row]
        self.showDataVC(data: data)
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // 刪除 Sql Data
            let deleteData = sqlDatas[indexPath.row]
            if database.deleteData(withID: deleteData.id) {
                sqlDatas.remove(at: indexPath.row)
                self.tableView.reloadData()
            }else{
                NSLog("Delete Error")
            }
        }
    }
}

extension FavoriteViewController : UISearchBarDelegate{
    // searchBar 將要被編輯
    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
        return true
    }
    // searchBar 將要結束編輯
    func searchBarShouldEndEditing(_ searchBar: UISearchBar) -> Bool {
        return true
    }
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        self.showNavSearchBar(false)
        searchBar.text = nil
        searchBar.endEditing(true)
        
        self.sqlDatas = database.searchAllData()
        self.tableView.reloadData()
    }
    // 鍵盤上 Search 鍵被按
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.endEditing(true)
        self.searchResult(searchBar.text)
        searchBar.endEditing(true)
    }
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        self.searchResult(searchText)
    }
    
    /// 根據搜尋文字取得搜尋結果
    func searchResult(_ searchText : String?){
        let allData = database.searchAllData()
        if searchText == nil || searchText?.count == 0 {
            self.sqlDatas = allData
            self.tableView.reloadData()
            return
        }
        // 看 data 中是否有包含關鍵字
        let datas = allData.filter { (data) -> Bool in
            // 全轉成小寫，再進行比對
            guard let text = searchText?.lowercased() else {
                return false
            }
            guard let note = data.note?.lowercased() else{
                return false
            }
            let noteBool = note.contains(text)
            guard let name = data.name?.lowercased() else{
                return false
            }
            let nameBool = name.contains(text)
            return noteBool || nameBool
        }
        self.sqlDatas = datas
        self.tableView.reloadData()
    }
}

extension FavoriteViewController{
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.searchBar.endEditing(true)
        if touches.first?.location(in: self.tableView) != nil{
            
        }
        
    }
}

