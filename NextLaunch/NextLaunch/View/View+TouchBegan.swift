//
//  ScrollView+TouchBegan.swift
//  NextLaunch
//
//  Created by Uran on 2018/3/16.
//  Copyright © 2018年 Uran. All rights reserved.
//

import Foundation
import UIKit
import MapKit
extension UIScrollView{
    open override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.endEditing(true)
    }
}
extension MKMapView{
    open override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.endEditing(true)
        
    }
}
