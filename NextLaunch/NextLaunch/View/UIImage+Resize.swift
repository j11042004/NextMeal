//
//  UIImage+Resize.swift
//
//  Created by BriefOS on 7/12/2559 BE.
//  Copyright © 2559 BriefOS. All rights reserved.
//

import UIKit

extension UIImage {
    func resizeImage(_ maxLength : CGFloat) -> UIImage?{
        
        if self.size.width <= maxLength && self.size.height <= maxLength {
            return self
        }
        let width = self.size.width
        let height = self.size.height
        // 圖片的 newSize
        var newSize: CGSize
        if width > height {
            let ratio  = width/maxLength
            newSize = CGSize(width: maxLength, height: height/ratio)
        }else{
            let ratio = height/maxLength
            newSize = CGSize(width: width/ratio, height: maxLength)
        }
        // 作圖的範圍
        let rect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)
        // 開啟作圖空間
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        // 把圖片畫到作圖空間上
        self.draw(in: rect)
        // 作圖空間轉成 Image
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        // 關閉作圖空間
        UIGraphicsEndImageContext()
        
        return newImage
    }
}
