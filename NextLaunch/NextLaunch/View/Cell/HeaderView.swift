//
//  HeaderView.swift
//  NextLaunch
//
//  Created by Uran on 2018/5/15.
//  Copyright © 2018年 Uran. All rights reserved.
//

import UIKit

class HeaderView: UITableViewHeaderFooterView {
    @IBOutlet weak var titleLabel: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        print("Header View awake")
    }
}
