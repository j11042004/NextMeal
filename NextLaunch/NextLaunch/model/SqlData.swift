//
//  SqlData.swift
//  NextLaunch
//
//  Created by Uran on 2018/3/15.
//  Copyright © 2018年 Uran. All rights reserved.
//

import UIKit
class SqlData: NSObject {
    var id : Int!
    var name : String?
    var latitude : Double?
    var longitude : Double?
    var note : String?
    var imageData : Data?
    
    public override init() {
        super.init()
    }
    
    public init(id : Int, name : String?, latitude : Double?, longitude : Double?, note : String?, imageData : Data?) {
        super.init()
        self.id = id
        self.name = name
        self.latitude = latitude
        self.longitude = longitude
        self.note = note
        self.imageData = imageData
    }
    public init(id : Int, name : String?, latitude : Double?, longitude : Double?, note : String?, image : UIImage?) {
        super.init()
        self.id = id
        self.name = name
        self.latitude = latitude
        self.longitude = longitude
        self.note = note
        var imgData : Data?
        // 將 image 轉成 data
        if let image = image{
            imgData = UIImagePNGRepresentation(image)
        }else{
            imgData = nil
        }
        self.imageData = imgData
    }
    
}
