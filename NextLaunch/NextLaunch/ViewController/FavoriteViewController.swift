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
    let dataSearch = DataSearch.shardInstance
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
        self.sqlDatas = database.searchAllData()
        self.tableView.reloadData()
        // 顯示 navigationBar
        self.navigationController?.navigationBar.isHidden = false
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
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
        dataCell.storeLabel.text = data.name
        dataCell.noteLabel.text = data.address
        
        dataCell.storeLabel.numberOfLines = 0
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
            // 判斷有沒有 id
            guard let dataID = deleteData.id else{
                return
            }
            if database.deleteData(withID: dataID) {
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
        searchBar.endEditing(true)
        guard let query = searchBar.text else {
            return
        }
        self.dataSearch.searchData(query: query) { (datas, errorMessage) in
            if let errorMsg = errorMessage{
                print("搜尋錯誤 :\(errorMsg)")
                return
            }
            guard let datas = datas else{
                return
            }
            self.sqlDatas = datas
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        // 判斷輸入自是否存在並且大於 0
        guard let query = searchBar.text,
                 query.count > 0
            else {
                // 顯示所有的 data
                self.sqlDatas = self.database.searchAllData()
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            return
        }
        // 搜尋有包含的關鍵字
        self.dataSearch.searchData(query: query) { (datas, errorMessage) in
            if let errorMsg = errorMessage{
                print("搜尋錯誤 :\(errorMsg)")
                return
            }
            guard let datas = datas else{
                return
            }
            self.sqlDatas = datas
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }
    
    
}

extension FavoriteViewController{
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.searchBar.endEditing(true)
        if touches.first?.location(in: self.tableView) != nil{
            
        }
        
    }
}

