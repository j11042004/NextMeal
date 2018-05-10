//
//  TableViewCell.swift
//  NextLaunch
//
//  Created by Uran on 2018/3/15.
//  Copyright © 2018年 Uran. All rights reserved.
//

import UIKit

class DataTableCell: UITableViewCell {

    @IBOutlet weak var storeLabel: UILabel!
    @IBOutlet weak var noteLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    override func didMoveToSuperview() {
        if let tableview = self.superview as? UITableView {
            tableview.beginUpdates()
            tableview.endUpdates()
        }
    }
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
