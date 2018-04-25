
//
//  ViewController.swift
//  swiftyRecorder
//
//  Created by Patrik Jonell on 2018-01-16.
//  Copyright © 2018 Patrik Jonell. All rights reserved.
//

import UIKit
import SceneKit
import ARKit
import AVFoundation



struct DataPack: Codable {
    let type: String
    let timestamp: Double
    let data: String
    
    private enum CodingKeys: String, CodingKey {
        case type
        case timestamp
        case data
        
    }
    
    //    func packFormat() -> [Packable] { //protocol function
    //        return [type, timestamp, data] //pack order
    //    }
    //
    //    func msgtype() -> MsgPackTypes {
    //        return .Custom
    //    }
}

class OlViewController: UIViewController, ARSCNViewDelegate, AVCaptureAudioDataOutputSampleBufferDelegate, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    @IBOutlet var sceneView: ARSCNView!
    var zmq_toggle: Bool = true
    var osc_toggle: Bool = true
    var osc_address: String = ""
    var osc_port: Int = 7001
    var phone_address: String = ""
    var audioRecorder: AVAudioRecorder!
    var recordingSession: AVAudioSession!
    var fileURL: URL!
    let session = AVCaptureSession()
    var blendShapeArray: [DataPack] = []
    private var videoConnection: AVCaptureConnection!
    private var audioConnection: AVCaptureConnection!
    
    
    @IBAction func swipeUp(_ sender: UISwipeGestureRecognizer) {
        //        print("stop!")
        //        recorder?.stopAndExport()
        //        let myVC = storyboard?.instantiateViewController(withIdentifier:"SecondViewController") as! SecondViewController
        //        myVC.zmq_toggle.isOn = self.zmq_toggle
        //        myVC.osc_toggle.isOn = self.osc_toggle
        //        myVC.osc_address.text = self.osc_address
        //        myVC.osc_port.text = self.osc_port.description
        //
        //        present(myVC, animated: true)
    }
    
    internal let writerQueue = DispatchQueue(label:"com.patrikjonell.WriterQueue")
    
    override func viewDidLoad() {
        do {
            fileURL = try FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent("votes.txt")
        } catch {
            print("aa")
        }
        
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        //        let fileURL = FileManager.default.temporaryDirectory // try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        //        recorder = RecordAR(ARSceneKit: sceneView)
        //        recorder?.record()
        //
        
        //        sceneView.preferredFramesPerSecond = 30
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        
        //        let DocumentDirURL = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        
        //
        
        print("hello")
        do {
            try "".write(to: self.fileURL, atomically: true, encoding: .utf8)
        } catch {
            print(error)
        }
        
        session.sessionPreset = AVCaptureSession.Preset.high
        print("patrik")
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        view.layer.addSublayer(previewLayer)
        
        var mic_input: AVCaptureDeviceInput!
        var video_input: AVCaptureDeviceInput!
        
        let audio_output = AVCaptureAudioDataOutput()
        let video_output = AVCaptureVideoDataOutput()
        
        audio_output.setSampleBufferDelegate(self, queue: DispatchQueue.main)
        
        video_output.setSampleBufferDelegate(self, queue: DispatchQueue.main)
        
        
        
        if let mic = AVCaptureDevice.default(for: AVMediaType.audio) {
            do
            {
                mic_input = try AVCaptureDeviceInput(device: mic)
            }
            catch
            {
                print("hello")
            }
        }
        
        if let video = AVCaptureDevice.default(for: AVMediaType.video) {
            do
            {
                video_input = try AVCaptureDeviceInput(device: video)
            }
            catch
            {
                print("hello")
            }
        }
        
        session.addInput(mic_input)
        //                session.addOutput(audio_output)
        
        session.addInput(video_input)
        //                session.addOutput(video_output)
        
        let queue = DispatchQueue(label: "com.patrikjonell.videosamplequeue")
        video_output.setSampleBufferDelegate(self, queue: queue)
        guard session.canAddOutput(video_output) else {
            fatalError()
        }
        session.addOutput(video_output)
        
        videoConnection = video_output.connection(with: .video)
        
        
        session.startRunning()
        
        
        //
        //
        
    }
    
    
    
    
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        writerQueue.async {
            //            print(connection.inputPorts.description)
            if connection == self.videoConnection
            {
//                let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
//                let timestamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
//                print(timestamp)
            }
        }
        //            writerQueue.async {
        //        print("yay")
        //        let block = CMSampleBufferGetDataBuffer(sampleBuffer)
        //        var length = 0
        //        var data: UnsafeMutablePointer<Int8>? = nil
        //        let status = CMBlockBufferGetDataPointer(block!, 0, nil, &length, &data)    // TODO: check for errors
        //        let result = NSData(bytesNoCopy: data!, length: length, freeWhenDone: false)
        ////
        ////
        ////        let dp = DataPack(type: "audio", timestamp: 1.2131, data: result.base64EncodedString())
        //////        let dataThing = DataPack.archive(w: dp)
        //////
        ////        let jsonData = try! JSONEncoder().encode(dp)
        //            do {
        ////                try jsonData.write(to: self.fileURL)
        //                let fileHandle = FileHandle(forWritingAtPath: self.fileURL.path)
        //                fileHandle?.seekToEndOfFile()
        //                fileHandle?.write(Data("audio".utf8))
        //                fileHandle?.write(Data("++++++*-------".utf8))
        //                fileHandle?.write(Data("1.2131".utf8))
        //                fileHandle?.write(Data("++++++*-------".utf8))
        //                fileHandle?.write(Data(result.base64EncodedString().utf8))
        //                fileHandle?.write(Data("////////xx$$$$$$".utf8))
        //                fileHandle?.closeFile()
        //            } catch {
        //                print(error)
        //            }
        //
        //
        ////        if let fileHandle = FileHandle(forWritingAtPath: fileURL.path) {
        ////            fileHandle.seekToEndOfFile()
        ////            fileHandle.write(dp)
        ////        }
        //            }
    }
    //
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARFaceTrackingConfiguration()
        
        // Run the view's session
        sceneView.session.run(configuration)
        //        let configuration = ARWorldTrackingConfiguration()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // Pause the view's session
        sceneView.session.pause()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }
    
    // MARK: - ARSCNViewDelegate
    
    func pixelBufferToUIImage(pixelBuffer: CVPixelBuffer) -> UIImage {
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let context = CIContext(options: nil)
        let cgImage = context.createCGImage(ciImage, from: ciImage.extent)
        let uiImage = UIImage(cgImage: cgImage!)
        return uiImage
    }
    
    // Override to create and configure nodes for anchors added to the view's session.
    public func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        print("here")
        guard let faceAnchor = anchor as? ARFaceAnchor else { return }
        let blendShapes = faceAnchor.blendShapes.description
        
        
        //        var time:CMTime {return CMTimeMakeWithSeconds(renderer.time, 1000000);}
        
        
        
        
        let current_time = CACurrentMediaTime().description
        
        writerQueue.async {
            //            print(self.fileURL.path)
            //            let fileHandle2 = FileHandle(forReadingAtPath: self.fileURL.path)
            //            print(fileHandle2)
            //
            //            fileHandle2?.seek(toFileOffset: 0)
            //            var data = fileHandle2?.readDataToEndOfFile()
            //            print(data)
            //
            //            data?.forEach { line in
            //                print(line)
            //            }
            //
            //            fileHandle2?.closeFile()
            
            
            
            
            do {
                //                    try ("------------------------------------------------------\n\n" + blendShapes + "////////////////////////////////////////////////////\n\n").write(to: fileURL, atomically: false, encoding: .utf8)
                
                //                    self.blendShapeArray.append(DataPack(type: "blendshape", timestamp: 1.2, data:blendShapes))
                
                //                    let fileHandle = FileHandle(forWritingAtPath: self.fileURL.path)
                //                    fileHandle?.seekToEndOfFile()
                //
                ////                    var aa = MessagePackValue(["blendshape", "1.1", blendShapes])
                //
                //                    fileHandle?.write(pack(items: [DataPack(type: "blendshape", timestamp: 1.2, data:blendShapes)]))
                //                    try pack(items: [DataPack(type: "blendshape", timestamp: 1.2, data:blendShapes.uppercased())]).write(to: self.fileURL)
                //                    fileHandle?.closeFile()
                //                        try (encode()) //.write(to: self.fileURL)
                
                //                    print("writing")
                
                //                    let jsonData = try! JSONEncoder().encode(DataPack(type: "blendshape", timestamp: 1.2, data:blendShapes))
                //                    try jsonData.write(to: self.fileURL)
            }
            catch {
                
                print("fail")
            }
            
            //            print(self.fileURL.path)
            
            //            let fileHandle = FileHandle(forWritingAtPath: self.fileURL.path)
            //                fileHandle?.seekToEndOfFile()
            ////                print(blendShapes.utf8)
            //                fileHandle?.write(Data(blendShapes.utf8))
            //                fileHandle?.closeFile()
            
        }
        do {
            //                                let text2 = try String(contentsOf: self.fileURL, encoding: .utf8)
            //                                print(text2)
            //                                let fileHandle2 = FileHandle(forReadingAtPath: self.fileURL.path)
            //
            //                                    var haha = fileHandle2?.readDataToEndOfFile()
            //                                    let data = NSData(bytes: &haha)
            //                                var weatherData = try NSData(contentsOf: self.fileURL)
            
            //                                var new_stuff = try weatherData?.itemsUnpacked(forAmount: 3, returnRemainingBytes: true)
            //            if new_stuff != nil {
            //                print(new_stuff)
            //                print(new_stuff?[0].castToString())
            //                print(new_stuff?[1].castToDouble)
            //                 print(new_stuff?[2].castToString())
            //            }
            
            //
            //
            //             let nobjsInOneGroup = 1
            //                                print(weatherData)
            //            try! weatherData?.unpackByGroupsWith(objectsInEachGroup: nobjsInOneGroup) { (unpackedData, isLast) -> Bool in
            //                print(unpackedData)
            //                return true
            //            }
            //            fileHandle2?.closeFile()
            //                        let unpackedItems = try data.itemsUnpacked()
            //                        print(unpackedItems)
            
            
            
        }
        catch {
            print("fail")
        }
        //        sceneView.session.
        //        if self.zmq_toggle {
        //
        //            let image = sceneView.session.currentFrame?.capturedImage
        ////            let data = UIImageJPEGRepresentation(pixelBufferToUIImage(pixelBuffer: image!), 1.0);
        ////            let strBase64 = data?.base64EncodedString(options: .lineLength64Characters)
        ////            let pointer = UnsafeBufferPointer(start:image, count:image.count)
        ////            let data = Data(buffer:pointer)
        //            let ciImage = CIImage(cvPixelBuffer: image!)
        //            let context = CIContext()
        //            let colorSpace = CGColorSpaceCreateDeviceRGB()
        //            let data = context.jpegRepresentation(of: ciImage, colorSpace: colorSpace, options:[:])
        //
        //            do {
        ////                try self.publisher?.send(string: current_time + "//--//" + blendShapes.map{ blendshape in
        ////                    blendshape.key.rawValue + ":" + blendshape.value.description
        ////                    }.description + "//--//" + strBase64!)
        //                var rot = "["
        //                for i in 0...3 {
        //                    for j in 0...3 {
        //                        rot += String(faceAnchor.transform[i][j]) + ","
        //                    }
        //                }
        //                rot = rot.dropLast() + "]"
        //
        ////                try self.publisher?.send(string: current_time + "//--//" + blendShapes.map{ blendshape in
        ////                    blendshape.key.rawValue + ":" + blendshape.value.description
        ////                    }.description + "//--//" + data!.base64EncodedString()  + "//--//" + rot)
        //
        //            } catch {
        //                print(error)
        //            }
        //        }
    }
    
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }
}

