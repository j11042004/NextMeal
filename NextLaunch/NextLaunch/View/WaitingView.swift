//
//  WaitingView.swift
//  NextLaunch
//
//  Created by Uran on 2018/5/9.
//  Copyright © 2018年 Uran. All rights reserved.
//

import UIKit

class WaitingView: UIView {
    private var view : UIView!
    @IBOutlet weak var activityView: UIActivityIndicatorView!
    
    
    convenience init(){
        self.init(frame: CGRect.zero)
    }
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.customerInit()
    }
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.customerInit()
    }
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    private func customerInit(){
        view = self.loadViewfromNib()
        self.addSubview(view)
    }
    
    private func loadViewfromNib() -> UIView {
        let xibStr = String(describing: type(of: self))
        let bundle = Bundle(for: type(of: self))
        let nib = UINib(nibName: xibStr, bundle: bundle)
        let view = nib.instantiate(withOwner: self, options: nil)[0] as! UIView
        view.frame = self.bounds
        return view
    }
    
    /// 顯示或隱藏 Waiting view
    public func showing(_ show : Bool){
        self.isHidden = !show
        self.activityView.isHidden = !show
    }
    /// 為 WaitingView設定佈滿的 Constraint
    ///
    /// - Parameter superView: 要佈滿的 View
    public func addWaitingViewConstraint(With superView : UIView){
        self.translatesAutoresizingMaskIntoConstraints = false
        self.topAnchor.constraint(equalTo: superView.topAnchor).isActive = true
        self.leftAnchor.constraint(equalTo: superView.leftAnchor).isActive = true
        self.rightAnchor.constraint(equalTo: superView.rightAnchor).isActive = true
        self.bottomAnchor.constraint(equalTo: superView.bottomAnchor).isActive = true
    }
}
