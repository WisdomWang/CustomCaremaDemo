//
//  CameraViewController.swift
//  CustomCaremaDemo
//
//  Created by Cary on 2018/7/9.
//  Copyright © 2018年 Cary. All rights reserved.
//

import UIKit
import AVFoundation

class CameraViewController: UIViewController,AVCapturePhotoCaptureDelegate {

   
    //捕获设备，通常是前置摄像头，后置摄像头，麦克风（音频输入）
    var device : AVCaptureDevice?
    //AVCaptureDeviceInput 代表输入设备，他使用AVCaptureDevice 来初始化
    var input : AVCaptureDeviceInput?
    //当启动摄像头开始捕获输入
    var output : AVCaptureMetadataOutput?
    //照片输出流
    var imageOutPut : AVCapturePhotoOutput?
    //session：由他把输入输出结合在一起，并开始启动捕获设备（摄像头）
    var session : AVCaptureSession?
    
    var photoSettings :AVCapturePhotoSettings?
    //图像预览层，实时显示捕获的图像
    var previewLayer : AVCaptureVideoPreviewLayer?
    //拍照按钮
    let photoButton = UIButton()
    //闪光灯按钮
    let flashButton = UIButton()
    //聚焦
    let focusView = UIView()
    //是否开启闪光灯
    var isFlashOn = Bool()
    //照片
    let imageView = UIImageView()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        isFlashOn = false
        self.view.backgroundColor = UIColor.clear
        if self.checkCameraPermission() {
            self.customCamera()
            self.initSubViews()
            self.focusAtPoint(point: CGPoint(x: 0.5, y: 0.5))
        }
       
    }
    func customCamera() {
        
        //使用AVMediaTypeVideo 指明self.device代表视频，默认使用后置摄像头进行初始化
        device = AVCaptureDevice.default(for:AVMediaType.video)!
        //使用设备初始化输入
        input = try!AVCaptureDeviceInput(device: device!)
        //生成输出对象
        output = AVCaptureMetadataOutput()
        imageOutPut = AVCapturePhotoOutput()
        //生成会话，用来结合输入输出
        session = AVCaptureSession()
        if (session?.canSetSessionPreset(.hd1920x1080))! {
            session?.canSetSessionPreset(.hd1920x1080)
        }
        if (session?.canAddInput(input!))! {
            session?.addInput(input!)
        }
        if (session?.canAddOutput(imageOutPut!))! {
            session?.addOutput(imageOutPut!)
        }
        //使用self.session，初始化预览层，self.session负责驱动input进行信息的采集，layer负责把图像渲染显示
        previewLayer = AVCaptureVideoPreviewLayer(session: session!)
        previewLayer?.frame = CGRect(x: 0, y: 0, width: kScreenWidth, height: kScreenHeight)
        previewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
        self.view.layer.addSublayer(previewLayer!)
        //开始启动
        session?.startRunning()
        
        photoSettings = AVCapturePhotoSettings.init(format:[AVVideoCodecKey:AVVideoCodecType.jpeg])
        
        if ((try?device?.lockForConfiguration()) != nil) {
            
            if ((imageOutPut?.supportedFlashModes) != nil) {
                
                photoSettings?.flashMode = .auto
            }
            if (device?.isWhiteBalanceModeSupported(.autoWhiteBalance))! {
                
                device?.whiteBalanceMode = .autoWhiteBalance
            }
            
        }
        device?.unlockForConfiguration()
    }
    
    func initSubViews() {
        
        let btn = UIButton()
        btn.frame = CGRect(x: 20, y: 20, width: 40, height: 40)
        btn.setTitle("取消", for: .normal)
        btn.addTarget(self, action: #selector(disMiss), for:.touchUpInside)
        self.view.addSubview(btn)
        
        photoButton.frame = CGRect(x: kScreenWidth/2.0-30, y: kScreenHeight-100, width: 60, height: 60)
        photoButton.setImage(UIImage(named: "photograph"), for:.normal)
        photoButton.addTarget(self, action: #selector(shutterCamera), for: .touchUpInside)
        self.view.addSubview(photoButton)
        
        focusView.frame = CGRect(x: 0, y: 0, width: 80, height: 80)
        focusView.layer.borderWidth = 1.0
        focusView.layer.borderColor = UIColor.green.cgColor
        self.view.addSubview(focusView)
        focusView.isHidden = true
        
        let leftButton = UIButton()
        leftButton.setTitle("切换", for:.normal)
        leftButton.titleLabel?.textAlignment = .center
        leftButton.sizeToFit()
        leftButton.center = CGPoint(x: (kScreenWidth - 60)/2.0/2.0, y: kScreenHeight-70)
        leftButton.addTarget(self, action:#selector(changeCamera), for:.touchUpInside)
        self.view.addSubview(leftButton)
        
        flashButton.setTitle("闪光灯关", for: .normal)
        flashButton.titleLabel?.textAlignment = .center
        flashButton.sizeToFit()
        flashButton.center = CGPoint(x: kScreenWidth-(kScreenWidth - 60)/2.0/2.0, y: kScreenHeight-70)
        flashButton.addTarget(self, action: #selector(FlashOn), for:.touchUpInside)
        self.view.addSubview(flashButton)
        
        self.view.addSubview(imageView)
        imageView.frame = CGRect(x:5, y: kScreenHeight-100, width: 60, height: 60)
    
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(focusGesture(gesture:)))
        self.view.addGestureRecognizer(tapGesture)
        
        let pinch = UIPinchGestureRecognizer(target: self, action: #selector(handlePinchGesture(recognizer:)))
 
        self.view.addGestureRecognizer(pinch)
        
    }
    
    @objc func handlePinchGesture(recognizer:UIPinchGestureRecognizer){
        
        var allTouchesAreOnThePreviewLayer = Bool()
        allTouchesAreOnThePreviewLayer = true
        let numTouches = recognizer.numberOfTouches
        for i in 0..<numTouches {
            let location = recognizer.location(ofTouch: i, in: self.view)
            let convertedLocation = previewLayer?.convert(location, from: previewLayer?.superlayer)
            if !(previewLayer?.contains(convertedLocation!))! {
                allTouchesAreOnThePreviewLayer = false
                break
            }
        }
        if allTouchesAreOnThePreviewLayer {
            
            var effectiveScale = recognizer.scale
            if effectiveScale < 1.0 {
                
                effectiveScale = 1.0
            }
            let maxScaleAndCropFactor = imageOutPut?.connection(with: .video)?.videoMaxScaleAndCropFactor
            if effectiveScale > maxScaleAndCropFactor! {
                
                effectiveScale = maxScaleAndCropFactor!
            }
            UIView.animate(withDuration: 0.025) {
                self.previewLayer?.affineTransform().scaledBy(x: effectiveScale, y: effectiveScale)
            }
            
        }
        
    }
    
    @objc func focusGesture(gesture:UITapGestureRecognizer) {
        
        var point : CGPoint
        point = gesture.location(in: gesture.view)
        self.focusAtPoint(point: point)
    }
    
    func focusAtPoint(point:CGPoint) {
        
        let size = self.view.bounds.size
         // focusPoint 函数后面Point取值范围是取景框左上角（0，0）到取景框右下角（1，1）之间,按这个来但位置就是不对，只能按上面的写法才可以。前面是点击位置的y/PreviewLayer的高度，后面是1-点击位置的x/PreviewLayer的宽度
        let focusPoint = CGPoint(x: point.y/size.height, y: 1 - point.x/size.width)
        
        if ((try?device?.lockForConfiguration()) != nil) {
            
            if (device?.isFocusModeSupported(.autoFocus))! {
                device?.focusPointOfInterest = focusPoint
                device?.focusMode = .autoFocus
            }
            if (device?.isExposureModeSupported(.autoExpose))! {
                device?.exposurePointOfInterest = focusPoint
                device?.exposureMode = .autoExpose
            }
            
        }
        device?.unlockForConfiguration()

        focusView.center = point
        focusView.isHidden = false
        UIView.animate(withDuration: 0.3, animations: {
           
            self.focusView.transform = CGAffineTransform.init(scaleX: 1.25, y: 1.25)
        }) { (finished) in
            
            UIView.animate(withDuration: 0.5, animations: {
                self.focusView.transform = CGAffineTransform.identity
            }, completion: { (finished) in
               self.focusView.isHidden = true
            })
        }
    }
    
    @objc func disMiss() {
        
        self.dismiss(animated: true, completion: nil)
    }
    @objc func shutterCamera() {
        
        let videoConnection = imageOutPut?.connection(with: .video)
        if (videoConnection == nil) {
            return
        }

        photoSettings = AVCapturePhotoSettings.init(format:[AVVideoCodecKey:AVVideoCodecType.jpeg])
        photoSettings?.flashMode = .auto
        imageOutPut?.capturePhoto(with:photoSettings!, delegate: self)
        
    }
    
    func saveImageWithImage(image:UIImage) {
    
           UIImageWriteToSavedPhotosAlbum(image, self, nil, nil);
           imageView.image = image
    }
    //代理方法
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let data = photo.fileDataRepresentation(),
            let image = UIImage.init(data: data) {
            self.saveImageWithImage(image: image)
        }
        
    }
    @objc func changeCamera() {
        
        var newCamera :AVCaptureDevice?
         newCamera = nil
        var newInput:AVCaptureDeviceInput?
         //获取当前相机的方向(前还是后)
        let position = input?.device.position
        //为摄像头的转换加转场动画
        let animation = CATransition()
        animation.timingFunction = CAMediaTimingFunction.init(name:kCAMediaTimingFunctionEaseInEaseOut)
        animation.duration = 0.5
        animation.type = "oglFlip"
        let type = AVCaptureDevice.DeviceType(rawValue: (device?.deviceType.rawValue)!) 
        if position == .front {
            //获取后置摄像头
            
            newCamera = AVCaptureDevice.default(type, for: .video, position: .back)
            animation.subtype = kCATransitionFromLeft
        }
        else {
            //获取前置摄像头
            newCamera = AVCaptureDevice.default(type, for: .video, position: .front)
            animation.subtype = kCATransitionFromRight
            
        }
        previewLayer?.add(animation, forKey: nil)
        newInput = try?AVCaptureDeviceInput(device: newCamera!)
        if (newInput != nil) {
            session?.beginConfiguration()
            session?.removeInput(input!)
            if (session?.canAddInput(newInput!))! {
                session?.addInput(newInput!)
                input = newInput
            }
            else {
                //如果不能加现在的input，就加原来的input
                session?.addInput(input!)
            }
            session?.commitConfiguration()
        }
    }

    @objc func FlashOn() {
        
      if ((try?device?.lockForConfiguration()) != nil) {
            
            if isFlashOn {
                
                if ((imageOutPut?.supportedFlashModes) != nil) {
                    
                    photoSettings?.flashMode = .off
                    isFlashOn = false
                    flashButton.setTitle("闪光灯关", for: .normal)
                }
                
            }
            
            else {
        
                if ((imageOutPut?.supportedFlashModes) != nil) {
                    
                    photoSettings?.flashMode = .on
                    isFlashOn = true
                    flashButton.setTitle("闪光灯开", for: .normal)
                }
            }
            
        }
        device?.unlockForConfiguration()
       
    }
    
    func checkCameraPermission() -> Bool {
        
        let authStatus = AVCaptureDevice.authorizationStatus(for: .video)
        if authStatus == .denied {
            print("请打开相机权限")
            return false
        }
        return true
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
