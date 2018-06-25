//
//  UIAlert+AddImageView.swift
//  NextLaunch
//
//  Created by Uran on 2018/6/1.
//  Copyright © 2018年 Uran. All rights reserved.
//

import Foundation
import UIKit
extension UIAlertController {
    func addImageView(With image : UIImage?)  {
        let imageAction = UIAlertAction(title: "", style: .default, handler: nil)
        imageAction.isEnabled = false
        let resizeImg = image?.resizeImage(250)
        imageAction.setValue(resizeImg, forKey: "image")
        self.addAction(imageAction)
    }
}



