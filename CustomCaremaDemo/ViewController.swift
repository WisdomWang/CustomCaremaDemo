//
//  ViewController.swift
//  CustomCaremaDemo
//
//  Created by Cary on 2018/7/9.
//  Copyright © 2018年 Cary. All rights reserved.
//

import UIKit


let kScreenWidth = UIScreen.main.bounds.size.width
let  kScreenHeight = UIScreen.main.bounds.size.height

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        let button = UIButton()
        button.frame = CGRect(x:kScreenWidth/2-50, y: 200, width: 100, height: 50)
        button.backgroundColor = UIColor.red
        button.setTitle("开始拍照", for: .normal)
        button.addTarget(self, action: #selector(buttonClick), for:.touchUpInside)
        self.view.addSubview(button)
    }

    
    @objc func buttonClick() {
        
        if !UIImagePickerController.isSourceTypeAvailable(.camera) {
            
           let alert = UIAlertController(title: "提示", message: "您的设备没有摄像头或者相关的驱动, 不能进行该操作！", preferredStyle: .alert)
            let action = UIAlertAction(title: "知道了", style: .cancel) { (alert) in
                
            }
            alert.addAction(action)
            self.present(alert, animated: true, completion: nil)
            return;
        }
        
        let vc = CameraViewController()
        self.present(vc, animated: true, completion: nil)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

