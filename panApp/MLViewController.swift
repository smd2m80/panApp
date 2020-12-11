import UIKit
import CoreMotion
import simd
import CoreML

//import SwiftUI

//@available(iOS 13.0, *)
class MLViewController: UIViewController {

    let appDelegate:AppDelegate = UIApplication.shared.delegate as! AppDelegate

    let motionManager = CMMotionManager()
    var attitude = SIMD3<Double>.zero
    var gyro = SIMD3<Double>.zero
    var gravity = SIMD3<Double>.zero
    var acc = SIMD3<Double>.zero
    var tapLocation = CGPoint(x: 0, y: 0)
    var touchB = 0
    var touchM = 0
    var tapCount = 0
    
    var isTapped = 0
    
    var format = DateFormatter()    //日付を取得
    let csvManager = SensorDataCsvManager()
    var text = ""
    var bufText = ""

    var i = 0
    var j = 0
    let endLabel = UILabel() // ラベルの生成
    var circleDraw :UIView!
    
    var iarray = [Int](1...90).shuffled()
    
    var preCircleNum = 0
    
    var myCircleNum = 0
    let uiImageView = UIImageView()
    var DisplayX = 0
    var DisplayY = 0
    let Finger:UIImage = UIImage(named:"Finger")!
    let Phone:UIImage = UIImage(named:"Phone")!
    
    let inputDataLength = 66
    var compAccArray = [Double]()
    var classLabel = ""
    var predictionCount = 0
    let MLOutLabel = UILabel()
    
    let Xmslen = 30
    
    var tappingFlag = false
    
    class Sensor{
        lazy var x = Array(repeating: 0.0, count: 30)
        lazy var y = Array(repeating: 0.0, count: 30)
        lazy var z = Array(repeating: 0.0, count: 30)
        lazy var scalar = Array(repeating: 0.0, count: 30)
        
        func removeAll(){
            x.removeAll()
            y.removeAll()
            z.removeAll()
            scalar.removeAll()
        }
        func cut(_ len:Int){
            x = x.suffix(len).map { $0 }
            y = y.suffix(len).map { $0 }
            z = z.suffix(len).map { $0 }
            scalar = scalar.suffix(len).map { $0 }
        }
        func append(_ add:SIMD3<Double>){
            x = x.dropFirst(1).map { $0 }
            y = y.dropFirst(1).map { $0 }
            z = z.dropFirst(1).map { $0 }
            scalar = scalar.dropFirst(1).map { $0 }
            x.append(add.x)
            y.append(add.y)
            z.append(add.y)
            scalar.append(add.x * add.y * add.z)
        }
        func add(_ add:SIMD3<Double>){
            x.append(add.x)
            y.append(add.y)
            z.append(add.y)
            scalar.append(add.x * add.y * add.z)
        }

        func mean() -> Array<Double>{
            return [x.average, y.average, z.average, scalar.average]
        }
        func varian() -> Array<Any>{
            return [x.variance(x), y.variance(y), z.variance(z), scalar.variance(scalar)]
        }
        func max() -> Array<Double?>{
            return [x.max(), y.max(), z.max(), scalar.max()]
        }
        
        func minus() -> Sensor{
            var dif = SIMD3<Double>.zero
            let difSensor = Sensor()
            for (index,_) in x.enumerated() {
                if index>0{
                    dif.x = x[index] - x[index-1]
                    dif.y = y[index] - y[index-1]
                    dif.z = z[index] - z[index-1]
                    difSensor.append(dif)
                }
            }
//            difSensor.cut(29)
            return difSensor
        }
                
    }
    
    class Sensors{
        var att = Sensor()
        var gyro = Sensor()
        var acc = Sensor()
        func append(_ addAtt:SIMD3<Double>, _ addGyro: SIMD3<Double>, _ addAcc: SIMD3<Double>){
            att.append(addAtt)
            gyro.append(addGyro)
            acc.append(addAcc)
        }
        func add(_ addAtt:SIMD3<Double>, _ addGyro: SIMD3<Double>, _ addAcc: SIMD3<Double>){
            att.add(addAtt)
            gyro.add(addGyro)
            acc.add(addAcc)
        }
        func cut(_ len: Int){
            att.cut(len)
            gyro.cut(len)
            acc.cut(len)
        }
        func minus() -> Sensors{
            let difSensors = Sensors()
            difSensors.att = att.minus()
            difSensors.gyro = gyro.minus()
            difSensors.acc = acc.minus()
            return difSensors
        }
        func mean() -> Array<Double>{
            var meanArray = [Double]()
            meanArray += att.mean()
            meanArray += gyro.mean()
            meanArray += acc.mean()
            meanArray.remove(at: 3) //att.scalarを削除
            return meanArray
        }
        func varian() -> Array<Any>{
            var meanArray = [Any]()
            meanArray += att.varian()
            meanArray += gyro.varian()
            meanArray += acc.varian()
            meanArray.remove(at: 3) //att.scalarを削除
            return meanArray
        }
        func max() -> Array<Double?>{
            var meanArray = [Double?]()
            meanArray += att.max()
            meanArray += gyro.max()
            meanArray += acc.max()
            meanArray.remove(at: 3) //att.scalarを削除
            return meanArray
        }

    }
    class RawDiff{
        var Raw = Sensors()
        var Diff = Sensors()
    }
    
    var attArray = Sensor()
    var gyroArray = Sensor()
    var accArray = Sensor()
    var diffaccArray = Sensor()
    var diffattArray = Sensor()
    var diffgyroArray = Sensor()
    var arrayMean = [Double](repeating: 0.0, count: 22)
    var arrayVar = [Double](repeating: 0.0, count: 22)
    var arrayMax = [Double](repeating: 0.0, count: 22)
    
    var rawSensors = Sensors()
    var diffSensors = Sensors()
    var rawdiff = RawDiff()

    var compDouble = [Any]()

    
    override func viewDidLoad() {
        super.viewDidLoad()

        startSensorUpdates(intervalSeconds: 0.01) // 100Hz
        csvManager.startRecording()

//        appDelegate.smallCirleX = 0
//        appDelegate.smallCirleY = 0
        
        iarray = [Int](1...90).shuffled()
//        iarray = [5,4,3,2,1]
        // tapセンサー
        let tapGesture:UITapGestureRecognizer = UITapGestureRecognizer(
            target: self,
            action: #selector(MLViewController.tapped(_:)))
        // デリゲートをセット
        tapGesture.delegate = self as? UIGestureRecognizerDelegate
        self.view.addGestureRecognizer(tapGesture)
        
        
        // Labelの書式
        endLabel.frame = CGRect(x: 0, y: 20, width: UIScreen.main.bounds.size.width, height: 44) // 位置とサイズの指定
        endLabel.textAlignment = NSTextAlignment.center // 横揃えの設定
        endLabel.textColor = UIColor.black // テキストカラーの設定
        endLabel.font = UIFont(name: "HiraKakuProN-W6", size: 17) // フォントの設定
        endLabel.text = "1セット/6セット"
        self.view.addSubview(endLabel) // ラベルの追加

    }
    
    @objc func tapped(_ sender: UITapGestureRecognizer){
        print("tap catch")
        if sender.state == .ended {

            rawdiff.Raw = rawSensors
            rawdiff.Diff = rawSensors.minus()

            print(rawdiff.Raw.att.x)
            compDouble += rawdiff.Raw.mean()
            compDouble += rawdiff.Raw.varian()
            compDouble += rawdiff.Raw.max() as Array<Any>
            compDouble += rawdiff.Diff.mean()
            compDouble += rawdiff.Diff.varian()
            compDouble += rawdiff.Diff.max() as Array<Any>
//            print(compDouble)

            
//            compDouble.append(rawSensors.minus())
            
            // add data for input CoreML
//            compAccArray.append(getCompositeData(sensorData: &compDouble))
            if compDouble.count >= inputDataLength {
                getCoremlOutput()
                compDouble.removeAll()
            }

            
            isTapped = 1
            i += 1
            print("curentCNum: ", myCircleNum)

            if iarray.count > 0{
                uiImageView.isHidden = true
                // 処理を現時点から0.5秒後に実行する
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.5) {
                    // bufTextをレコード
                    self.csvManager.addRecordText(addText: self.bufText)
                    self.bufText = self.text
                    self.text = ""

                    self.preCircleNum = self.myCircleNum
                    self.drawNewMarker()
                    print(self.iarray)
                    
                    if self.i==15 { //15drag終わり
                        self.i = 0
                        self.j += 1
                    }
                    self.endLabel.text = String(self.j+1)+"セット/6セット"
                }
                    
                    
            }else{ //listを消費したら、record
                // ここで最後のタップにミスがないか尋ねる
                self.csvManager.addRecordText(addText: bufText)
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.5) {
                    self.csvManager.addRecordText(addText: self.text)
                    if self.csvManager.isRecording{
                        self.csvManager.stopRecording()
                        
                        // save csv file
                        self.format.dateFormat = "yyyy-MMdd-HHmmss"
                        
                        let dateText = "touch_" + "100Hz" + self.format.string(from: Date())
                        self.endLabel.text = "おしまい"
                        self.view.backgroundColor = .gray

                        self.showSaveCsvFileAlert(fileName: dateText)
                    }else{
                        self.dismiss(animated: true, completion: nil)   //VC破棄
                    }
                }
            }
            
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        touchB = 1
        let touch = touches.first!
        tapLocation = touch.location(in: self.view)
        tapCount += 1
        tappingFlag = true
    }
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            touchM = 1
            tapLocation = touch.location(in: self.view)
        }
    }
    
    func startSensorUpdates(intervalSeconds:Double) {
        if motionManager.isDeviceMotionAvailable{
            motionManager.deviceMotionUpdateInterval = intervalSeconds
            
            // start sensor updates
            motionManager.startDeviceMotionUpdates(to: OperationQueue.current!, withHandler: {(motion:CMDeviceMotion?, error:Error?) in
                self.getMotionData(deviceMotion: motion!)
                
            })
        }
    }
    func getMotionData(deviceMotion:CMDeviceMotion) {
        
//        refAttitude.x = referenceAttitude.pitch
//        refAttitude.y = referenceAttitude.roll
//        refAttitude.z = referenceAttitude.yaw
//        gravity.x = deviceMotion.gravity.x
//        gravity.y = deviceMotion.gravity.y
//        gravity.z = deviceMotion.gravity.z
        attitude.x = deviceMotion.attitude.pitch
        attitude.y = deviceMotion.attitude.roll
        attitude.z = deviceMotion.attitude.yaw
        
        gyro.x = deviceMotion.rotationRate.x
        gyro.y = deviceMotion.rotationRate.y
        gyro.z = deviceMotion.rotationRate.z
        acc.x = deviceMotion.userAcceleration.x
        acc.y = deviceMotion.userAcceleration.y
        acc.z = deviceMotion.userAcceleration.z

        if tappingFlag{
            rawSensors.add(attitude,gyro,acc)
        }else{
            rawSensors.append(attitude,gyro,acc)
        }
        // record sensor data
        if csvManager.isRecording {
//            format.dateFormat = "MMddHHmmssSSS"
            format.dateFormat = DateFormatter.dateFormat(fromTemplate: "yyyyMMddHHmmssSSS", options: 0, locale: Locale(identifier: "ja_JP"))
            
//            var text = ""
            text += format.string(from: Date()) + ","
            
            text += String(attitude.x) + ","
            text += String(attitude.y) + ","
            text += String(attitude.z) + ","
            text += String(gyro.x) + ","
            text += String(gyro.y) + ","
            text += String(gyro.z) + ","
            text += String(gyro.x * gyro.y * gyro.z) + ","
//            text += String(gravity.x) + ","
//            text += String(gravity.y) + ","
//            text += String(gravity.z) + ","
            text += String(acc.x) + ","
            text += String(acc.y) + ","
            text += String(acc.z) + ","
            text += String(acc.x * acc.y * acc.z) + ","
            
            text += String(DisplayX) + ","
            text += String(DisplayY) + ","
//            text += appDelegate.smallCirleX.description + ","
//            text += appDelegate.smallCirleY.description + ","

            text += tapLocation.x.description + ","
            text += tapLocation.y.description + ","
            
            text += String(touchB) + ","
            touchB = 0
            text += String(touchM) + ","
            touchM = 0
            text += String(isTapped) + ","
            isTapped = 0

            text += String(myCircleNum) + "\n"

//            csvManager.addRecordText(addText: text)
        }
    }
    
    func showSaveCsvFileAlert(fileName:String){
        let alertController = UIAlertController(title: "Save CSV file", message: "Enter file name to add.", preferredStyle: .alert)
        
        let defaultAction:UIAlertAction =
            UIAlertAction(title: "OK",
                          style: .default,
                          handler:{
                            (action:UIAlertAction!) -> Void in
                            let textField = alertController.textFields![0] as UITextField
                            self.csvManager.saveSensorDataToCsv(fileName: textField.text!)
                            self.dismiss(animated: true, completion: nil)   //VC破棄

            })
        let cancelAction:UIAlertAction =
            UIAlertAction(title: "Cancel",
                          style: .cancel,
                          handler:{
                            (action:UIAlertAction!) -> Void in
                            self.showDeleteRecordedDataAlert(fileName: fileName)
            })
        
        alertController.addTextField { (textField:UITextField!) -> Void in
            alertController.textFields![0].text = fileName
        }
        alertController.addAction(defaultAction)
        alertController.addAction(cancelAction)
        
        present(alertController, animated: true, completion: nil)
    }
    func showDeleteRecordedDataAlert(fileName:String){
        let alertController = UIAlertController(title: "Delete recorded data", message: "Do you delete recorded data?", preferredStyle: .alert)
        
        let defaultAction:UIAlertAction =
            UIAlertAction(title: "OK",
                          style: .default,
                          handler:{
                            (action:UIAlertAction!) -> Void in
                            // delete recorded data
                            self.dismiss(animated: true, completion: nil)   //VC破棄

            })
        let cancelAction:UIAlertAction =
            UIAlertAction(title: "Cancel",
                          style: .cancel,
                          handler:{
                            (action:UIAlertAction!) -> Void in
                            self.showSaveCsvFileAlert(fileName: fileName)
            })
        
        alertController.addAction(defaultAction)
        alertController.addAction(cancelAction)
        
        present(alertController, animated: true, completion: nil)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // retry
    @IBAction func buttonActionSheet(_ sender : Any) {
           // UIAlertController
           let alertController:UIAlertController =
               UIAlertController(title:"タップをミスった？",
                                 message: "前回のタップを削除します",
                                 preferredStyle: .actionSheet)
           self.uiImageView.isHidden = true

           let actionDelete = UIAlertAction(title: "YES", style: .destructive){
               action in
            print("push YES! preN: ", self.preCircleNum)
            self.bufText = ""
            self.text = ""
            self.iarray.append(contentsOf: [self.myCircleNum, self.preCircleNum])
            print(self.iarray)
            // 処理を現時点から0.5秒後に実行する
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.1) {
                self.drawNewMarker()
            }
            
           }
           
           let actionCancel = UIAlertAction(title: "Cancel", style: .cancel){
               (action) -> Void in
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.5) {
                self.uiImageView.isHidden = false
                print("Cancel")
            }
           }
           
           // actionを追加
           alertController.addAction(actionDelete)
           alertController.addAction(actionCancel)
           
           // UIAlertControllerの起動
           present(alertController, animated: true, completion: nil)
       }
    
    // safeArea取得
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        if #available(iOS 11.0, *) {
            appDelegate.safeAreaTop = self.view.safeAreaInsets.top
            appDelegate.safeAreaBottom = self.view.safeAreaInsets.bottom
            appDelegate.safeAreaLeft = self.view.safeAreaInsets.left
            appDelegate.safeAreaLeft = self.view.safeAreaInsets.right
        }
        // Screen Size の取得
        appDelegate.screenWidth = self.view.bounds.width
        appDelegate.screenHeight = self.view.bounds.height
        appDelegate.safeAreaHeight = appDelegate.screenHeight-appDelegate.safeAreaTop - appDelegate.safeAreaBottom
//        print("CircleL:",appDelegate.screenWidth ?? 0,"R: ",appDelegate.safeAreaHeight)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        drawNewMarker()
    }
    
    func drawNewMarker(){
        myCircleNum = iarray.popLast() ?? 0
        if (myCircleNum%2 != 0) {
            uiImageView.image = Finger
        }else{
            uiImageView.image = Phone
        }
        uiImageView.frame = CGRect(x:0, y:0, width:70, height:70)
        
        DisplayX = Int(appDelegate.screenWidth/3) * (myCircleNum%3) + Int.random(in: 35 ..< (Int(appDelegate.screenWidth/3)-35) )
        DisplayY = Int(appDelegate.safeAreaTop) +  Int(appDelegate.safeAreaHeight/3) * (myCircleNum%9/3) + Int.random(in: 35 ..< (Int(appDelegate.safeAreaHeight/3)-35) )
        
        // 画像の表示場所 中心座標の位置を指定
        uiImageView.center = CGPoint(x:DisplayX, y:DisplayY)

        self.view.addSubview(uiImageView)
        self.uiImageView.isHidden = false

    }
    
    func getCompositeData(sensorData:inout SIMD3<Double>) -> Double{
            let compData = sqrt((sensorData.x * sensorData.x) + (sensorData.y * sensorData.y) + (sensorData.z * sensorData.z))
            
            return compData
    }
        
    func getCoremlOutput(){
        // store sensor data in array for CoreML model
        let dataNum = NSNumber(value:inputDataLength)
        var mlarray = try! MLMultiArray(shape: [dataNum], dataType: MLMultiArrayDataType.double )
        for (index, data) in compDouble.enumerated(){
            mlarray[index] = data as! NSNumber
        }
//        print("raw: ", mlarray)
                
        let stdModel = Yymefm300_std()
        let transed = try? stdModel.prediction(input: mlarray)
        mlarray = transed!.transformed_features
//        print("stded: ", mlarray)
        
        // input data to CoreML model
        let model = MLyymefm300()
        guard let output = try? model.prediction(input:
                                                    MLyymefm300Input(attXMean: Double(mlarray[0]) , attYMean: Double(mlarray[1]), attZMean: Double(mlarray[2]), gyroXMean: Double(mlarray[3]), gyroYMean: Double(mlarray[4]), gyroZMean: Double(mlarray[5]), gyroScalarMean: Double(mlarray[6]), accXMean: Double(mlarray[7]), accYMean: Double(mlarray[8]), accZMean: Double(mlarray[9]), accScalarMean: Double(mlarray[10]), diff_attXMean: Double(mlarray[11]), diff_attYMean: Double(mlarray[12]), diff_attZMean: Double(mlarray[13]), diff_gyroXMean: Double(mlarray[14]), diff_gyroYMean: Double(mlarray[15]), diff_gyroZMean: Double(mlarray[16]), diff_gyroScalarMean: Double(mlarray[17]), diff_accXMean: Double(mlarray[18]), diff_accYMean: Double(mlarray[19]), diff_accZMean: Double(mlarray[20]), diff_accScalarMean: Double(mlarray[21]), attXVar: Double(mlarray[22]), attYVar: Double(mlarray[23]), attZVar: Double(mlarray[24]), gyroXVar: Double(mlarray[25]), gyroYVar: Double(mlarray[26]), gyroZVar: Double(mlarray[27]), gyroScalarVar: Double(mlarray[28]), accXVar: Double(mlarray[29]), accYVar: Double(mlarray[30]), accZVar: Double(mlarray[31]), accScalarVar: Double(mlarray[32]), diff_attXVar: Double(mlarray[33]), diff_attYVar: Double(mlarray[34]), diff_attZVar: Double(mlarray[35]), diff_gyroXVar: Double(mlarray[36]), diff_gyroYVar: Double(mlarray[37]), diff_gyroZVar: Double(mlarray[38]), diff_gyroScalarVar: Double(mlarray[39]), diff_accXVar: Double(mlarray[40]), diff_accYVar: Double(mlarray[41]), diff_accZVar: Double(mlarray[42]), diff_accScalarVar: Double(mlarray[43]), attXMax: Double(mlarray[44]), attYMax: Double(mlarray[45]), attZMax: Double(mlarray[46]), gyroXMax: Double(mlarray[47]), gyroYMax: Double(mlarray[48]), gyroZMax: Double(mlarray[49]), gyroScalarMax: Double(mlarray[50]), accXMax: Double(mlarray[51]), accYMax: Double(mlarray[52]), accZMax: Double(mlarray[53]), accScalarMax: Double(mlarray[54]), diff_attXMax: Double(mlarray[55]), diff_attYMax: Double(mlarray[56]), diff_attZMax: Double(mlarray[57]), diff_gyroXMax: Double(mlarray[58]), diff_gyroYMax: Double(mlarray[59]), diff_gyroZMax: Double(mlarray[60]), diff_gyroScalarMax: Double(mlarray[61]), diff_accXMax: Double(mlarray[62]), diff_accYMax: Double(mlarray[63]), diff_accZMax: Double(mlarray[64]), diff_accScalarMax: Double(mlarray[65]))) else {
                fatalError("Unexpected runtime error.")
        }
//        classLabel = output.tapID
        print(output.tapID)
        predictionCount += 1
        
//        displayModelOutput()
        // Labelの書式
        MLOutLabel.frame = CGRect(x: 0, y: 120, width: UIScreen.main.bounds.size.width, height: 44) // 位置とサイズの指定
        MLOutLabel.textAlignment = NSTextAlignment.center // 横揃えの設定
        MLOutLabel.textColor = UIColor.black // テキストカラーの設定
        MLOutLabel.font = UIFont(name: "HiraKakuProN-W6", size: 17) // フォントの設定
        MLOutLabel.text = "1セット/6セット"
        self.view.addSubview(endLabel) // ラベルの追加
    }
    
    
}

extension Collection where Element: Numeric {
    /// Returns the total sum of all elements in the array
    var total: Element { return reduce(0, +) }
}

extension Collection where Element: BinaryInteger {
    /// Returns the average of all elements in the array
    var average: Double {
        return isEmpty ? 0 : Double(total) / Double(count)
    }
}

extension Collection where Element: BinaryFloatingPoint {
    /// Returns the average of all elements in the array
    var average: Element {
        return isEmpty ? 0 : total / Element(count)
    }
}
extension Array where Element == Double{
    //総和
    //全体の各要素を足し合わせるだけ。
    func sum(_ array:[Double])->Double{
        return array.reduce(0,+)
    }
    //平均値
    //全体の総和をその個数で割る。
    func ave(_ array:[Double])->Double{
        return self.sum(array) / Double(array.count)
    }
    //分散
    //求め方が２つあるが、計算量が少ないと思われる方法を採用。
    //V=E[X^2]-E[X]^2が成立。
    func variance(_ array:[Double])->Double{
        let left=self.ave(array.map{pow($0, 2.0)})
        let right=pow(self.ave(array), 2.0)
        let count=array.count
        return (left-right)*Double(count/(count-1))
    }
    //標準偏差
    //これは分散の正の平方根。つまりS=√V
    func standardDeviation(_ array:[Double]) -> Double {
        return sqrt(self.variance(array))
    }
}
