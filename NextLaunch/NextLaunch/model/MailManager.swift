//
//  MailManager.swift
//  NextLaunch
//
//  Created by Uran on 2018/5/14.
//  Copyright © 2018年 Uran. All rights reserved.
//

import UIKit
import MessageUI
class MailManager: NSObject , MFMailComposeViewControllerDelegate {
    public static let shardInstance = MailManager()
    private var receivers : [String]?
    private var message : String!
    private let rootVC = RootVCManager.standard
    typealias completion = (_ isShowing : Bool) -> Void
    // MARK: - 寄送 mail Alert
    /// 寄送 mail
    func sendMail(With receivers:[String] ,Message message : String! ,Completion completion : completion?){
        self.receivers = receivers
        self.message = message
        let alert = UIAlertController(title: "Waring !", message: "來信聊聊", preferredStyle: .alert)
        let connect = UIAlertAction(title: "寄吧", style: .default) { (action) in
            self.sendMail()
            completion?(false)
        }
        let cancel = UIAlertAction(title: "取消", style: .cancel) { (_) in
            completion?(false)
        }
        alert.addAction(connect)
        alert.addAction(cancel)
        DispatchQueue.main.async {
            UIApplication.shared.keyWindow?.rootViewController?.present(alert, animated: true, completion: nil)
        }
    }
    /// 寄送郵件
    private func sendMail(){
        let mailComposeViewController = configuredMailComposeViewController()
        if MFMailComposeViewController.canSendMail() {
            DispatchQueue.main.async {
               UIApplication.shared.keyWindow?.rootViewController?.present(mailComposeViewController, animated: true, completion: nil)
            }
            
        } else {
            NSLog("無法寄送信件")
        }
    }
    // 建立寄送 Email 的 Alert
    private func configuredMailComposeViewController() -> MFMailComposeViewController {
        let mailComposerVC = MFMailComposeViewController()
        mailComposerVC.mailComposeDelegate = self
        //email 地址
        mailComposerVC.setToRecipients(self.receivers)
        // Email title
        mailComposerVC.setSubject("來自下一餐吃啥")
        // Email 內容
        mailComposerVC.setMessageBody(self.message, isHTML: false)
        
        return mailComposerVC
    }
}
extension MailManager {
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        if let error = error {
            NSLog("寄信錯誤: \(error.localizedDescription)")
            return
        }
        // 關閉 寄信頁面
        controller.dismiss(animated: true, completion: nil)
    }
}
