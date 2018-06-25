//
//  MoreViewController.swift
//  NextLaunch
//
//  Created by Uran on 2018/5/10.
//  Copyright © 2018年 Uran. All rights reserved.
//

import UIKit
import StoreKit
class MoreViewController: UIViewController {
    enum ContentType {
        case More
        case Iap
        case Mail
        case Share
    }
    // 開啟 app 的網址可用  http:// , with itms:// , itms-apps:// 選一個
    // app 頁面： itunes.apple.com/app/idxxxxxxxxxx
    // 開發者頁面itunes.apple.com/developer/id1282864882
    private let shareUrl = URL(string: "https://itunes.apple.com/developer/id1282864882")!
    private let mail = MailManager.shardInstance
    // TableView
    
    private let cellID = "Cell"
    private let headerID = "header"
    private let footID = "footer"
    private let cellsDict = ["More and more","贊助一杯咖啡","寄信告知","認同請分享！"]
    private let cellIcons = ["☞","☕️","📮","💯"]
    private let cellKind = [ContentType.More , ContentType.Iap , ContentType.Mail , ContentType.Share]
    @IBOutlet weak var tableView: UITableView!
    var footerHeight : CGFloat = 0
    var headerHeight : CGFloat = 80
    let tableColor = UIColor.lightGray
    // Iap
    // 要先設定 productIDs 才可以取得 商品資訊
    var productIDs : [String] = ["ios.uran.tea"]
    let manager : IAPManager = IAPManager.sharedInstance
    var products : [SKProduct]!
    // 等待 View
    private let waitView = WaitingView()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.addSubview(self.waitView)
        self.waitView.showing(false)
        self.waitView.addWaitingViewConstraint(With: self.view)
        //  註冊 HeaderView
        let bundle = Bundle(for: MoreViewController.self)
        let headerNib = UINib(nibName: "HeaderView", bundle: bundle)
        self.tableView.register(headerNib, forHeaderFooterViewReuseIdentifier: self.headerID)
        // 註冊 FooterView
        let footerNib = UINib(nibName: "FooterView", bundle: bundle)
        self.tableView.register(footerNib, forHeaderFooterViewReuseIdentifier: self.footID)
        
        // 更換背景
        self.view.backgroundColor = tableColor
        self.tableView.backgroundColor = tableColor
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tableView.delegate = self
        self.tableView.dataSource = self
        
        
        self.manager.delegate = self
        self.products = manager.products
        if self.products.count == 0 {
            NSLog("尚未取得商品，再次要求")
            self.manager.requestProductFromApple(WithProductIDs: self.productIDs)
        }
        
        
    }
    /// 更多 App
    func moreApp() {
        if #available(iOS 10.0, *) {
            UIApplication.shared.open(shareUrl, options: [:], completionHandler: nil)
        } else {
            UIApplication.shared.openURL(shareUrl)
        }
    }
    /// 贊助
    func giveIapTea() {
        guard let product = self.products.first else {
            print("第一件是 Nil")
            return
        }
        self.waitView.showing(true)
        self.manager.buyProduct(With: product)
    }
    /// 寄信
    func sendMail() {
        let receivers = ["j11042004@gmail.com"]
        mail.sendMail(With: receivers, Message: "Hello 你好嗎？", Completion: nil)
    }
    /// 分享功能
    func shareApp() {
        let shareAll : [Any] = [shareUrl] as [Any]
        let activityVC = UIActivityViewController(activityItems: shareAll, applicationActivities: nil)
        activityVC.popoverPresentationController?.sourceView = self.view
        self.present(activityVC, animated: true, completion: nil)
    }
}
extension MoreViewController : UITableViewDelegate , UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.cellsDict.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellID, for: indexPath) as! MoreCell
        let info = self.cellsDict[indexPath.row]
        let icon = self.cellIcons[indexPath.row]
        cell.titleLabel.text = info
        cell.iconLabel.text = icon
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let kind = self.cellKind[indexPath.row]
        switch kind {
        case .More:
            self.moreApp()
            break
        case .Iap:
            self.giveIapTea()
            break
        case .Mail:
            self.sendMail()
            break
        case .Share:
            self.shareApp()
            break
        }
    }
    
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let headerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: self.headerID) as? HeaderView else{
            print("headerView is nil")
            return nil
        }
        headerView.titleLabel.text = "👍 更多資訊"
        // 使用 Xib 的 HeaderView 要改顏色要這樣做
        headerView.contentView.backgroundColor = UIColor.lightGray
        
        return headerView
    }
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return self.headerHeight
    }
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        guard let footerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: self.footID) as? FooterView else{
            print("footerView is nil")
            return nil
        }
        footerView.infoLabel.text = "🚨 App 中產生的資訊只做參考用，請勿隨意用在違法用途"
        footerView.infoLabel.numberOfLines = 0
        footerView.infoLabel.sizeToFit()
        footerView.contentView.backgroundColor = tableColor
        return footerView
    }
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        guard tableView.visibleCells.count != 0 else {
            return self.footerHeight
        }
        // 取的 max Cell
        guard let maxCell = tableView.visibleCells.last else{
            return self.footerHeight
        }
        // 計算 Cell 與 View 底部的位址
        let cellsMaxY = maxCell.frame.maxY
        var height = self.view.frame.height - cellsMaxY - self.headerHeight
        // 若有 tabbar 就扣除 tabbar 的值
        if let tabbar = self.tabBarController?.tabBar{
            height -= tabbar.frame.height
        }
        // 是否要更換 FooterView 的高
        if height > self.footerHeight {
            self.footerHeight = height
            return self.footerHeight
        }
        return self.footerHeight
    }
    
    
}

extension MoreViewController : IAPManagerDelegate{
    func managerBoughtProduct(With productID: String) {
        NSLog("Bought product id : \(productID)")
        self.waitView.showing(false)
    }
    func managerGotAllProduct(With products: [SKProduct]) {
        self.products = products
    }
    func managerDidChangeTranscationState(With istranstation: Bool) {
        self.waitView.showing(false)
    }
}

