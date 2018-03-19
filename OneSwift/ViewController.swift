//
//  ViewController.swift
//  OneSwift
//
//  Created by OneLei on 2018/1/20.
//  Copyright © 2018年 OneLei. All rights reserved.
//

import UIKit
import OneRubberPageControl

class ViewController: UIViewController {
    
    let page = OneRubberPageControl.init(frame: CGRect.init(x: 100, y: 100, width: 200, height: 100), count: 5)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        page.valueChange = { index in
            print("Closure : Page is \(index)")
        }
        view.backgroundColor = UIColor.white
        view.addSubview(page)
        
        page.addTarget(self, action: #selector(targetActionValueChange(_:)), for: UIControlEvents.valueChanged)
    }
    
    @objc func targetActionValueChange(_ page: OneRubberPageControl) {
        print("Target-Action : Page is \(page.currentIndex)")
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

