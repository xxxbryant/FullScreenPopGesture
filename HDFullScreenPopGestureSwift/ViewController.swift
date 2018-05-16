//
//  ViewController.swift
//  HDFullScreenPopGestureSwift
//
//  Created by HD-XXZQ-iMac on 2018/5/16.
//  Copyright © 2018年 HD-XXZQ-iMac. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        self.hd_allowPopDistance = 200
//        self.hd_popDisabled = false
        self.hd_navigationBarHidden = true

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

