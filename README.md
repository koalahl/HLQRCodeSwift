# HLQRCodeSwift

#Usage

##基本初始化方法
```swift
SLQRCodeScanner { (qrVC, result, status) in

}
```

##带网络请求的初始化方法：
```objc
let qrScanner = SLQRCodeScanner(scanCompleteClosure: { (qrVC, result, status) in if status == .success{ print(result)}},
request: (urlString,{(data) in
print("data = \(data)")
let alert = UIAlertView(title: nil, message: String(data), delegate: nil
, cancelButtonTitle: "OK ")

alert.show()
}))

self.presentViewController(qrScanner, animated: true, completion: nil)
```

##可配置属性的初始化方法：
```swift
SLQRCodeScanner(tip: "", color: UIColor.blackColor(), scanCompleteClosure: { (qrVC, result, status) in

}, request: nil)
```