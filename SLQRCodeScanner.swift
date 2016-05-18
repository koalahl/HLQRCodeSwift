//
//  SLQRCodeScanner.swift
//  StarLib
//
//  Created by HanLiu on 16/5/5.
//  Copyright © 2016年 HanLiu. All rights reserved.
//

import UIKit
import AVFoundation

let kDeviceWidth  = UIScreen.mainScreen().bounds.size.width
let kDeviceHeight = UIScreen.mainScreen().bounds.size.height
let kDeviceFrame  = UIScreen.mainScreen().bounds

let kQRCodeReaderMinY:CGFloat   = 120.0
let kQRCodeReaderMaxY:CGFloat   = 360.0
let kQRCodeReaderWidth:CGFloat  = 240.0
let kQRCodeReaderHeight:CGFloat = 240.0

class Scanner {
    var session:AVCaptureSession
    var previewLayer:AVCaptureVideoPreviewLayer
    weak var delegate:AVCaptureMetadataOutputObjectsDelegate?
    
    
    init(){
        
        self.session      = AVCaptureSession()
        self.previewLayer = AVCaptureVideoPreviewLayer(session: self.session)
        
    }

    func buildScanner(delegate:AVCaptureMetadataOutputObjectsDelegate?) -> Void {
        
        let device = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo)
        let input  = try!AVCaptureDeviceInput.init(device: device)
        let output = AVCaptureMetadataOutput()
        output.setMetadataObjectsDelegate(delegate, queue: dispatch_get_main_queue())
        
        if session.canAddInput(input) {
            session.addInput(input)
        }
        if session.canAddOutput(output) {
            session.addOutput(output)
        }
        
        output.metadataObjectTypes = [AVMetadataObjectTypeQRCode,AVMetadataObjectTypeEAN8Code,AVMetadataObjectTypeEAN13Code,AVMetadataObjectTypeCode128Code]
        output.rectOfInterest = CGRectMake(kQRCodeReaderMinY/kDeviceHeight, (kDeviceWidth - kQRCodeReaderWidth)/2/kDeviceWidth, kQRCodeReaderHeight/kDeviceHeight, kQRCodeReaderWidth/kDeviceWidth)
        
        previewLayer.frame = kDeviceFrame
        previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
     
    }
}

enum ScannerStatus {
    case success
    case fail
}

class SLQRCodeScanner: UIViewController ,AVCaptureMetadataOutputObjectsDelegate{
    typealias QRCodeScanResult = (qrVC:UIViewController,result:String?,status:ScannerStatus)->Void
    typealias Response = (response:AnyObject?)->Void
    typealias Request = (String,Response)
    var qrScanCompletion:QRCodeScanResult
    
    var url :String?
    var response:Response?
    var request:Request?

    var tipText:String?
    var color:UIColor?
    var codeString = ""
    let scanner:Scanner
    
    init(tip:String?,color:UIColor?,scanCompleteClosure:QRCodeScanResult,request:Request?){
        
        self.tipText = tip
        self.color   = (color != nil) ? color : UIColor(colorLiteralRed: 0.85, green: 0.23, blue: 0.18, alpha: 1)
        self.qrScanCompletion = scanCompleteClosure
        self.request = request
        self.url      = request!.0
        self.response = request!.1
        
        self.scanner = Scanner()
        super.init(nibName: nil, bundle: nil)
        
    }
    convenience init(scanCompleteClosure:QRCodeScanResult){
        self.init(tip: nil,color: nil,scanCompleteClosure: scanCompleteClosure,request: nil)
        
    }
    convenience init(scanCompleteClosure:QRCodeScanResult,request:Request){
        self.init(tip: nil,color: nil,scanCompleteClosure: scanCompleteClosure,request: request)
        
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
  
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        setupNavigation()
        
        setQRReaderPickScope()
        
        scanner.buildScanner(self)
       
        self.view.layer.insertSublayer(scanner.previewLayer, atIndex: 0)
        
        startScan()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    


    func setupNavigation() {
        let nav = UIView(frame:CGRect(x: 0, y: 0, width: kDeviceWidth, height: 64))
        nav.backgroundColor = color
        self.view.addSubview(nav)
        
        let title = UILabel(frame: CGRectMake(kDeviceWidth/2-50, 24, 100, 30))
        title.text = "扫描条形码"
        title.font = UIFont.systemFontOfSize(14)
        title.textAlignment = .Center
        nav.addSubview(title)
        
        let backBtn = UIButton(type: .Custom)
        backBtn.frame = CGRectMake(20, 28, 60, 24);
        backBtn.setImage(UIImage(named: "bar_back"), forState: .Normal)
        backBtn.addTarget(self, action: #selector(SLQRCodeScanner.cancelScan), forControlEvents: .TouchUpInside)
        nav.addSubview(backBtn)
    }

    func setQRReaderPickScope()  {
        let upView = UIView(frame: CGRect(x: 0, y: 64, width: kDeviceWidth, height: kQRCodeReaderMinY-64))
        upView.alpha = 0.4
        upView.backgroundColor = UIColor.blackColor()
        self.view.addSubview(upView)
        
        let leftView = UIView(frame: CGRect(x: 0, y: kQRCodeReaderMinY, width: (kDeviceWidth - kQRCodeReaderWidth)/2.0, height: kQRCodeReaderHeight))
        leftView.alpha = 0.4
        leftView.backgroundColor = UIColor.blackColor()
        self.view.addSubview(leftView)
        
        
        let rightView = UIView(frame: CGRect(x: kDeviceWidth - CGRectGetMaxX(leftView.frame), y: kQRCodeReaderMinY, width: CGRectGetMaxX(leftView.frame), height: kQRCodeReaderHeight))
        rightView.alpha = 0.4
        rightView.backgroundColor = UIColor.blackColor()
        self.view.addSubview(rightView)
        
        let space_h = kDeviceHeight - kQRCodeReaderMaxY
        
        let bottomView = UIView(frame: CGRect(x: 0, y: kQRCodeReaderMaxY, width: kDeviceWidth, height: space_h))
        bottomView.alpha = 0.4
        bottomView.backgroundColor = UIColor.blackColor()
        self.view.addSubview(bottomView)
        
        //Scanner scope
        let scanCropView = UIView(frame: CGRect(x: (kDeviceWidth-kQRCodeReaderWidth)/2,y: kQRCodeReaderMinY,width: kQRCodeReaderWidth, height: kQRCodeReaderHeight))
        scanCropView.layer.borderColor = (color != nil) ? color?.CGColor : UIColor(colorLiteralRed: 0.85, green: 0.23, blue: 0.18, alpha: 1).CGColor
        scanCropView.layer.borderWidth = 2.0
        self.view.addSubview(scanCropView)
        
        
        let tipLabel = UILabel(frame: CGRect(x: kDeviceWidth/2-120, y: CGRectGetMaxY(scanCropView.frame)+20, width: 240, height: 24))
        tipLabel.text =  (tipText != nil) ? tipText : "将条形码置于框中即可快速扫描"
        tipLabel.textAlignment = .Center
        self.view.addSubview(tipLabel)
    }
    
    //MARK: Capture Delegate
    func captureOutput(captureOutput: AVCaptureOutput!, didOutputMetadataObjects metadataObjects: [AnyObject]!, fromConnection connection: AVCaptureConnection!) {
        
        if metadataObjects.count > 0 {
            stopScan()
            let metadataObject:AVMetadataMachineReadableCodeObject = metadataObjects.first as! AVMetadataMachineReadableCodeObject
            
            if let value = metadataObject.stringValue {
                    self.qrScanCompletion(qrVC: self,result: value,status:.success)
                
                codeString = value
                request(self.url!, completion: self.response!)
            }else {
                    self.qrScanCompletion(qrVC: self,result: nil,status:.fail)
                
            }
            
        }else{
                self.qrScanCompletion(qrVC: self,result: nil,status:.fail)
        
        }
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    //MARK: --Start/stop/cancel
    func startScan() {
        scanner.session.startRunning()
    }
    
    func stopScan()  {
        scanner.session.stopRunning()

    }
    func cancelScan() {
        scanner.session.stopRunning()
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func request(url:String,completion:Response)  {
        let completionIn = completion
        let newUrl = url + codeString
        let request = NSMutableURLRequest(URL: NSURL(string: newUrl)!, cachePolicy: .UseProtocolCachePolicy, timeoutInterval: 0)
        request.HTTPMethod = "GET"
        
        let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
        let session = NSURLSession(configuration: configuration , delegate: nil, delegateQueue: nil)
        let task = session.dataTaskWithRequest(request) { (data, response, error) in
            if (error == nil) {
                let jsonData = try!NSJSONSerialization.JSONObjectWithData(data!, options: .MutableLeaves)
                completionIn(response: jsonData)
            }
        }
        task.resume()
        
//        Cherries.Get(newUrl) { (data, response, error) in
//            completionIn(response: data)
//        }
        
    }
}

