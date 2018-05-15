//
//  TabBarViewController.swift
//  NextLaunch
//
//  Created by Uran on 2018/5/8.
//  Copyright © 2018年 Uran. All rights reserved.
//

import UIKit

class TabBarViewController: UITabBarController , UITabBarControllerDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    override func viewWillAppear(_ animated: Bool) {
        // 選擇自己要的 vc index
        self.selectedIndex = 2
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        
    }
}
