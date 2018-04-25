//
//  ViewController.swift
//  swiftyApp
//
//  Created by Patrik Jonell on 2018-01-16.
//  Copyright © 2018 Patrik Jonell. All rights reserved.
//

import UIKit
import SceneKit
import ARKit
import AVFoundation
import SwiftyZeroMQ

class ViewController: UIViewController, ARSCNViewDelegate, ARSessionDelegate, AVCaptureAudioDataOutputSampleBufferDelegate, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    @IBOutlet var sceneView: ARSCNView!
    var fileURL: URL!
    var dataFileURL: URL!
    var geometryFileURL: URL!
    var session: AVCaptureSession!
    private var videoConnection: AVCaptureConnection!
    private var audioConnection: AVCaptureConnection!
    private var previewLayer: AVCaptureVideoPreviewLayer?
    var fileWriter: AVAssetWriter!
    var videoInput: AVAssetWriterInput!
    var audioInput: AVAssetWriterInput!
    var timedBlendShapeInput: AVAssetWriterInputMetadataAdaptor!
    private var isRecordingSessionStarted: Bool = false
    var adaptor: AVAssetWriterInputPixelBufferAdaptor!
    var starButton: UILabel = UILabel()
    var firstFram2e: TimeInterval!
    var counter: Int = 0
    var running:Bool = false
    var firstGeometryLine:Bool = true
    
    @IBAction func swipe_up(_ sender: Any) {
        
            if self.running {
                self.session.stopRunning()
                self.videoInput.markAsFinished()
                self.audioInput.markAsFinished()

                self.fileWriter.finishWriting {
                   
                    print("here - done")
                    DispatchQueue.main.async {
                        self.starButton.text = ""
                    }
                    UISaveVideoAtPathToSavedPhotosAlbum(self.fileWriter.outputURL.path, nil, nil, nil);
                    
//                    do {
//                        let fileHandle2 = try FileHandle(forUpdating: self.geometryFileURL)
//                        fileHandle2.seekToEndOfFile()
//                        fileHandle2.write(Data("]".utf8))
//                        fileHandle2.closeFile()
//                    } catch {
//                        print(error)
//                    }
                    
                    
//                  let vc = UIActivityViewController(activityItems: [self.dataFileURL, self.fileURL, self.geometryFileURL], applicationActivities: [])
                    let vc = UIActivityViewController(activityItems: [self.dataFileURL, self.fileURL], applicationActivities: [])
                  self.present(vc, animated: true, completion: nil)
                    self.running = false
                    self.isRecordingSessionStarted = false
                }
//                    let fileHandle2 = FileHandle(forReadingAtPath: self.dataFileURL.path)
//                    let fileHandle3 = FileHandle(forReadingAtPath: self.fileURL.path)
                
                
//                }
               
                
//                self.session.stopRunning()
            } else {
                DispatchQueue.main.async {
                    self.starButton.text = "recording.."
                }
                print("starting!")
                do {
                    self.fileURL = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true).appendingPathComponent("video-" + NSUUID().uuidString + ".mp4")
                    self.dataFileURL = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true).appendingPathComponent("video-blendshapes" + NSUUID().uuidString + ".csv")
//                    self.geometryFileURL = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true).appendingPathComponent("video-geometry" + NSUUID().uuidString + ".json")
                } catch {
                    print(error)
                }
                
                
//                    self.fileURL =  URL(fileURLWithPath: NSTemporaryDirectory())
//                        .appendingPathComponent(UUID().uuidString)
//                        .appendingPathExtension("mp4")
                
//                    self.dataFileURL =  URL(fileURLWithPath: NSTemporaryDirectory())
//                        .appendingPathComponent(UUID().uuidString)
//                        .appendingPathExtension("txt")
                
                    let fileManager = FileManager.default
//                    fileManager.createFile(atPath: self.fileURL.path, contents: nil)
                    fileManager.createFile(atPath: self.dataFileURL.path, contents: nil)
//                    fileManager.createFile(atPath: self.geometryFileURL.path, contents: Data("[".utf8))
                
                    do {
                        fileWriter = try AVAssetWriter(outputURL: self.fileURL, fileType: AVFileType.mp4)
                    } catch {
                        print(error)
                    }
                    fileWriter!.movieFragmentInterval = kCMTimeInvalid
                    fileWriter!.shouldOptimizeForNetworkUse = false
                    
                    let videoOutputSettings: Dictionary<String, Any> = [
                        AVVideoCodecKey : AVVideoCodecType.h264,
                        AVVideoWidthKey : 1280,
                        AVVideoHeightKey : 720
                    ];
                    
                    //automaticallyConfiguresCaptureDeviceForWideColor
                    
                
                
                    videoInput = AVAssetWriterInput(mediaType: AVMediaType.video, outputSettings: videoOutputSettings)
                    
                    //        let sourcePixelBufferAttributesDictionary : [String: AnyObject] = [
                    //            kCVPixelBufferPixelFormatTypeKey as String: NSNumber(value: kCVPixelFormatType_32BGRA),
                    //            kCVPixelBufferWidthKey as String: NSNumber(value: 3088),
                    //            kCVPixelBufferHeightKey as String: NSNumber(value: 2320)
                    //        ]
                    
                
//
//                    adaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: videoInput, sourcePixelBufferAttributes: [kCVPixelBufferPixelFormatTypeKey as AnyHashable as! String: NSNumber(value: kCVPixelFormatType_32BGRA)])
                    adaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: videoInput)
                
                    videoInput.expectsMediaDataInRealTime = true
                    fileWriter.add(videoInput)
                    
                    
                    let audioOutputSettings: Dictionary<String, Any> = [
                        AVFormatIDKey : kAudioFormatMPEG4AAC,
                        AVNumberOfChannelsKey : 2,
                        AVSampleRateKey : 44100.0,
                        AVEncoderBitRateKey : 192000
                    ]
                    audioInput = AVAssetWriterInput(mediaType: AVMediaType.audio, outputSettings: audioOutputSettings)
                    audioInput.expectsMediaDataInRealTime = true
                    fileWriter.add(audioInput)
                
                    
                    
                    
                    //        session.sessionPreset = AVCaptureSession.Preset.medium
                    
                
                self.session.startRunning()
                self.running = true
            }
        
    }
    
    
    
//    internal let sessionQueue = DispatchQueue(label:"com.patrikjonell.SessionQueue")
    let sessionQueue: DispatchQueue = DispatchQueue(label: "sampleBuffer", attributes: [])
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        
        
        do {
////
//            self.fileURL = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true).appendingPathComponent("video-" + NSUUID().uuidString + ".mp4")
//            self.dataFileURL = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true).appendingPathComponent("video-" + NSUUID().uuidString + "txt")
//
//            if fileManager.fileExists(atPath: self.fileURL.path) {
//                try fileManager.removeItem(atPath: self.fileURL.path)
//            }
//
//            if fileManager.fileExists(atPath: self.dataFileURL.path) {
//                try fileManager.removeItem(atPath: self.dataFileURL.path)
//            }
//
//            self.fileURL = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true).appendingPathComponent("video-4.mp4")
//            self.dataFileURL = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true).appendingPathComponent("video-4.txt")
//
        } catch {
            print(error)
        }
//
        
//        let directory = NSTemporaryDirectory()
        
        
        // This returns a URL? even though it is an NSURL class method
//        self.fileURL = NSURL.fileURL(withPathComponents: [directory, NSUUID().uuidString])?.appendingPathExtension("mp4")
//        self.dataFileURL = NSURL.fileURL(withPathComponents: [directory, NSUUID().uuidString])?.appendingPathExtension("txt")
//
//        do {
//            try fileManager.createFile(atPath: self.fileURL.path, contents: nil)
//            try fileManager.createFile(atPath: self.dataFileURL.path, contents: nil)
//        } catch {
//            print(error)
//        }
//
        
        
        
        
        

        
        
        
        // Set the view's delegate
        sceneView.delegate = self
        
        
//        sceneView.preferredFramesPerSecond = 30
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
     
        
        session = AVCaptureSession()
        self.previewLayer = AVCaptureVideoPreviewLayer(session: session)
        //        previewLayer!.frame = view.layer.frame
        //        sceneView.layer.insertSublayer(previewLayer!, at: 0)
        self.previewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
        //        sceneView.layer.addSublayer(previewLayer!)
        self.previewLayer?.frame = self.view.bounds
        self.view.layer.addSublayer(previewLayer!)
        
        
        self.sceneView.frame = self.view.bounds
        self.sceneView.backgroundColor = UIColor.clear
        
        
        
        session.beginConfiguration()
        
        //        var video_input: AVCaptureDeviceInput!
        //        let video = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front)
        //
        ////        let video = AVCaptureDevice.default(for: .video)
        //        do {
        //            video_input = try AVCaptureDeviceInput(device: video!)
        //        } catch {
        //            print(error)
        //        }
        //        session.addInput(video_input)
        //
        
        var mic_input: AVCaptureDeviceInput!
        let mic = AVCaptureDevice.default(for: .audio)
        do {
            mic_input = try AVCaptureDeviceInput(device: mic!)
        } catch {
            print(error)
        }
        session.addInput(mic_input)
        
        
        //        let video_output = AVCaptureVideoDataOutput()
        ////        video_output.videoSettings = [kCVPixelBufferPixelFormatTypeKey as AnyHashable as! String: NSNumber(value: kCVPixelFormatType_32BGRA)]
        //        video_output.alwaysDiscardsLateVideoFrames = false
        ////        let video_queue = DispatchQueue(label: "com.patrikjonell.videosamplequeue")
        //        video_output.setSampleBufferDelegate(self, queue: sessionQueue)
        //        session.addOutput(video_output)
        //        videoConnection = video_output.connection(with: .video)
        ////
        
        let audio_output = AVCaptureAudioDataOutput()
        //        let audio_queue = DispatchQueue(label: "com.patrikjonell.audiosamplequeue")
        audio_output.setSampleBufferDelegate(self, queue: sessionQueue)
        session.addOutput(audio_output)
        audioConnection = audio_output.connection(with: .audio)
        
        //
        
        //        previewLayer = AVCaptureVideoPreviewLayer(session: session);
        
        //
        
        
        
        
        self.session.commitConfiguration()
        
        
//
//        do {
//            try "".write(to: self.fileURL, atomically: true, encoding: .utf8)
//        } catch {
//            print(error)
//        }
//
        
        
        
        
        self.starButton.frame = CGRect(x: 10, y: 10, width: 100, height: 100)
        self.starButton.text = ""
        self.starButton.textColor = .red
//        starButton.addTarget(self, action: #selector(ViewController.starButtonClicked), for: .touchUpInside)
        sceneView.addSubview(self.starButton)
//
//
//
//
        
        
//        sessionQueue.async {
        
//        }
        
        
//
//
//
//        assetWriter.startWriting()
//        assetWriter.startSession(atSourceTime: kCMTimeZero)
//
        
   
    }
    
//    @IBAction func starButtonClicked(_ sender:UIButton!){
//
//
//    }
//
//    func captureOutput(captureOutput: AVCaptureFileOutput!, didFinishRecordingToOutputFileAtURL outputFileURL: NSURL!, fromConnections connections: [AnyObject]!, error: NSError!) {
//        print(error)
//    }
//
//    func captureOutput(_ output: AVCaptureOutput, didDrop: CMSampleBuffer, from: AVCaptureConnection) {
//        print("drop")
//    }
//

    var recordingInProgress:Bool = false
    var video_frames_written: Bool = false
    
//
//    func capturdsaffsfeOutput(_ captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection!) {
//
//        if CMSampleBufferDataIsReady(sampleBuffer) == false
//        {
//            // Handle error
//            return;
//        }
//        let startTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
//
//        if self.fileWriter.status == AVAssetWriterStatus.unknown {
//            self.fileWriter.startWriting()
//            self.fileWriter.startSession(atSourceTime: startTime)
//            self.recordingInProgress = true
//            return
//        }
//
//        if self.fileWriter.status == AVAssetWriterStatus.failed {
//            // Handle error here
//            return;
//        }
//
//        // Here you collect each frame and process it
//
//        if(self.recordingInProgress){
//
//            if let _ = captureOutput as? AVCaptureVideoDataOutput {
//
//                if self.videoInput.isReadyForMoreMediaData{
//                    self.videoInput.append(sampleBuffer)
//                    self.video_frames_written = true
//                }
//            }
//            if let _ = captureOutput as? AVCaptureAudioDataOutput {
//                if self.videoInput.isReadyForMoreMediaData && self.video_frames_written {
//                    self.audioInput.append(sampleBuffer)
//                }
//
//            }
//
//        }
//
//    }
//
//
//
//
//
//
//
//
//
           func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
////            print(self.sceneView.session.currentFrame?.anchors)
            if self.running  {
            sessionQueue.async {
            if !self.isRecordingSessionStarted {
                let presentationTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
//                print(presentationTime)
                self.fileWriter.startWriting()
                self.fileWriter?.startSession(atSourceTime: presentationTime)
                self.isRecordingSessionStarted = true
                return
            }
////             writerQueue.async {
////            print(connection.inputPorts.description)
//            if connection == self.videoConnection
//            {
//
////                print("video")
//
//                self.videoInput.append(sampleBuffer)
//
////                   print("YAY!")
////                let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
////                let timestamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
////                print(timestamp)
//            }
            if connection == self.audioConnection {
//                    print("audio")
                    self.audioInput.append(sampleBuffer)
            }
                }
            }
    }
////            writerQueue.async {
////        print("yay")
////        let block = CMSampleBufferGetDataBuffer(sampleBuffer)
////        var length = 0
////        var data: UnsafeMutablePointer<Int8>? = nil
////        let status = CMBlockBufferGetDataPointer(block!, 0, nil, &length, &data)    // TODO: check for errors
////        let result = NSData(bytesNoCopy: data!, length: length, freeWhenDone: false)
//////
//////
//////        let dp = DataPack(type: "audio", timestamp: 1.2131, data: result.base64EncodedString())
////////        let dataThing = DataPack.archive(w: dp)
////////
//////        let jsonData = try! JSONEncoder().encode(dp)
////            do {
//////                try jsonData.write(to: self.fileURL)
////                let fileHandle = FileHandle(forWritingAtPath: self.fileURL.path)
////                fileHandle?.seekToEndOfFile()
////                fileHandle?.write(Data("audio".utf8))
////                fileHandle?.write(Data("++++++*-------".utf8))
////                fileHandle?.write(Data("1.2131".utf8))
////                fileHandle?.write(Data("++++++*-------".utf8))
////                fileHandle?.write(Data(result.base64EncodedString().utf8))
////                fileHandle?.write(Data("////////xx$$$$$$".utf8))
////                fileHandle?.closeFile()
////            } catch {
////                print(error)
////            }
////
////
//////        if let fileHandle = FileHandle(forWritingAtPath: fileURL.path) {
//////            fileHandle.seekToEndOfFile()
//////            fileHandle.write(dp)
//////        }
////            }
//    }
//    }
//
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print("Hello!")
        // Create a session configuration
        let configuration = ARFaceTrackingConfiguration()
        
        // Run the view's session
        sceneView.session.run(configuration)
        sceneView.session.delegate = self
//        let configuration = ARWorldTrackingConfiguration()
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        print("Bye!")
        // Pause the view's session
        sceneView.session.pause()
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }
    
    // MARK: - ARSCNViewDelegate
    
//    func pixelBufferToUIImage(pixelBuffer: CVPixelBuffer) -> UIImage {
//        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
//        let context = CIContext(options: nil)
//        let cgImage = context.createCGImage(ciImage, from: ciImage.extent)
//        let uiImage = UIImage(cgImage: cgImage!)
//        return uiImage
//    }
    
    // Override to create and configure nodes for anchors added to the view's session.
    
//    var firstFrame: TimeInterval!
    
//    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
//        if firstFrame == nil {
//            firstFrame = time
//        }
//
//
//        if self.adaptor.assetWriterInput.isReadyForMoreMediaData && self.isRecordingSessionStarted  {
//            self.adaptor.append(sceneView.session.currentFrame!.capturedImage, withPresentationTime: CMTimeMakeWithSeconds(time, 1000000))
////            print("frame..")
//        }
//    }
    
    
//    public func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
//        print(renderer)
////
//        sessionQueue.sync {
//        guard let faceAnchor = anchor as? ARFaceAnchor else { return }
//        let blendShapes = faceAnchor.blendShapes.description
//        print(renderer)
//        var newItem = AVMutableMetadataItem()
//        newItem.value = "hello" as NSString
////        newItem.key = AVMetadata
////        newItem.identifier = AVMetadataIdentifierQuickTimeMetadataLocationISO6709
////        newItem.dataType = kCMMetadataDataType_QuickTimeMetadataLocation_ISO6709 as String
////        newItem.duration = asset.duration
//
//        var metadataTimedGroup = AVMutableTimedMetadataGroup()
//        metadataTimedGroup.items.append(newItem)
//        var theTime = CMTimeMakeWithSeconds(renderer.sceneTime, 1000000)
//
//        metadataTimedGroup.timeRange = CMTimeRange(start: theTime, duration: CMTime(seconds: 0, preferredTimescale: 1))
//            timedBlendShapeInput.append(metadataTimedGroup)
//
        
//        print(blendShapes)
        
//         CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
        
        
        
//        }}
//
////        var time:CMTime {return CMTimeMakeWithSeconds(renderer.time, 1000000);}
//
//
//
//
//        let current_time = CACurrentMediaTime().description
//
//        writerQueue.async {
////            print(self.fileURL.path)
////            let fileHandle2 = FileHandle(forReadingAtPath: self.fileURL.path)
////            print(fileHandle2)
////
////            fileHandle2?.seek(toFileOffset: 0)
////            var data = fileHandle2?.readDataToEndOfFile()
////            print(data)
////
////            data?.forEach { line in
////                print(line)
////            }
////
////            fileHandle2?.closeFile()
//
//
//
//
//                do {
////                    try ("------------------------------------------------------\n\n" + blendShapes + "////////////////////////////////////////////////////\n\n").write(to: fileURL, atomically: false, encoding: .utf8)
//
////                    self.blendShapeArray.append(DataPack(type: "blendshape", timestamp: 1.2, data:blendShapes))
//
////                    let fileHandle = FileHandle(forWritingAtPath: self.fileURL.path)
////                    fileHandle?.seekToEndOfFile()
////
//////                    var aa = MessagePackValue(["blendshape", "1.1", blendShapes])
////
////                    fileHandle?.write(pack(items: [DataPack(type: "blendshape", timestamp: 1.2, data:blendShapes)]))
////                    try pack(items: [DataPack(type: "blendshape", timestamp: 1.2, data:blendShapes.uppercased())]).write(to: self.fileURL)
////                    fileHandle?.closeFile()
////                        try (encode()) //.write(to: self.fileURL)
//
////                    print("writing")
//
////                    let jsonData = try! JSONEncoder().encode(DataPack(type: "blendshape", timestamp: 1.2, data:blendShapes))
////                    try jsonData.write(to: self.fileURL)
//                }
//                catch {
//
//                    print("fail")
//            }
//
////            print(self.fileURL.path)
//
////            let fileHandle = FileHandle(forWritingAtPath: self.fileURL.path)
////                fileHandle?.seekToEndOfFile()
//////                print(blendShapes.utf8)
////                fileHandle?.write(Data(blendShapes.utf8))
////                fileHandle?.closeFile()
//
//        }
//        do {
////                                let text2 = try String(contentsOf: self.fileURL, encoding: .utf8)
////                                print(text2)
////                                let fileHandle2 = FileHandle(forReadingAtPath: self.fileURL.path)
//            //
////                                    var haha = fileHandle2?.readDataToEndOfFile()
////                                    let data = NSData(bytes: &haha)
////                                var weatherData = try NSData(contentsOf: self.fileURL)
//
////                                var new_stuff = try weatherData?.itemsUnpacked(forAmount: 3, returnRemainingBytes: true)
////            if new_stuff != nil {
////                print(new_stuff)
////                print(new_stuff?[0].castToString())
////                print(new_stuff?[1].castToDouble)
////                 print(new_stuff?[2].castToString())
////            }
//
//            //
//            //
////             let nobjsInOneGroup = 1
////                                print(weatherData)
////            try! weatherData?.unpackByGroupsWith(objectsInEachGroup: nobjsInOneGroup) { (unpackedData, isLast) -> Bool in
////                print(unpackedData)
////                return true
////            }
////            fileHandle2?.closeFile()
//            //                        let unpackedItems = try data.itemsUnpacked()
//            //                        print(unpackedItems)
//
//
//
//        }
//        catch {
//            print("fail")
//        }
////        sceneView.session.
////        if self.zmq_toggle {
////
////            let image = sceneView.session.currentFrame?.capturedImage
//////            let data = UIImageJPEGRepresentation(pixelBufferToUIImage(pixelBuffer: image!), 1.0);
//////            let strBase64 = data?.base64EncodedString(options: .lineLength64Characters)
//////            let pointer = UnsafeBufferPointer(start:image, count:image.count)
//////            let data = Data(buffer:pointer)
////            let ciImage = CIImage(cvPixelBuffer: image!)
////            let context = CIContext()
////            let colorSpace = CGColorSpaceCreateDeviceRGB()
////            let data = context.jpegRepresentation(of: ciImage, colorSpace: colorSpace, options:[:])
////
////            do {
//////                try self.publisher?.send(string: current_time + "//--//" + blendShapes.map{ blendshape in
//////                    blendshape.key.rawValue + ":" + blendshape.value.description
//////                    }.description + "//--//" + strBase64!)
////                var rot = "["
////                for i in 0...3 {
////                    for j in 0...3 {
////                        rot += String(faceAnchor.transform[i][j]) + ","
////                    }
////                }
////                rot = rot.dropLast() + "]"
////
//////                try self.publisher?.send(string: current_time + "//--//" + blendShapes.map{ blendshape in
//////                    blendshape.key.rawValue + ":" + blendshape.value.description
//////                    }.description + "//--//" + data!.base64EncodedString()  + "//--//" + rot)
////
////            } catch {
////                print(error)
////            }
////        }
//    }
//
    
    
    

        
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        
     
        
sessionQueue.async {
        if self.isRecordingSessionStarted && self.adaptor.assetWriterInput.isReadyForMoreMediaData  {
            if self.firstFram2e == nil {
                self.firstFram2e = frame.timestamp
            }
            self.adaptor.append(frame.capturedImage, withPresentationTime: CMTimeMakeWithSeconds(frame.timestamp, 1000000))
            
            guard let faceAnchor = frame.anchors.first as? ARFaceAnchor else { return }
            let blendShapes = faceAnchor.blendShapes

            let tim = frame.timestamp - self.firstFram2e
//            print(frame.capturedDepthData?.depthDataMap)
//            var geometry_json = ""
//            if self.firstGeometryLine {
//                geometry_json += "{"
//                self.firstGeometryLine = false
//            } else {
//                geometry_json += ",{"
//            }
//            geometry_json += "\"frameNo\": " + String(self.counter) + ","
//            geometry_json += "\"timestamp\": " + String(tim) + ","
//            geometry_json += "\"textureCoordinates\": " + faceAnchor.geometry.textureCoordinates.description + ","
//            geometry_json += "\"triangleCount\": " + faceAnchor.geometry.triangleCount.description + ","
//            geometry_json += "\"triangleIndices\": " + faceAnchor.geometry.triangleIndices.description + ","
//            geometry_json += "\"vertices\": " + faceAnchor.geometry.vertices.description + ","
//            geometry_json += "},"
            
            do {
//                let fileHandle2 = try FileHandle(forUpdating: self.geometryFileURL)
//                fileHandle2.seekToEndOfFile()
//                fileHandle2.write(Data(geometry_json.utf8))
//                fileHandle2.closeFile()
                
                let fileHandle = try FileHandle(forUpdating: self.dataFileURL)
                fileHandle.seekToEndOfFile()
                
                var csvString = String(self.counter) + "," + String(tim) + ","
                
                for i in 0...3 {
                    for j in 0...3 {
                        csvString += String(faceAnchor.transform[i][j]) + ","
                    }
                }
                csvString += blendShapes.map{ blendshape in blendshape.key.rawValue + ":" + blendshape.value.description}.joined(separator: ",") + "\n"
            
                fileHandle.write(Data(csvString.utf8))
                fileHandle.closeFile()
                self.counter += 1
                
            } catch {
                print(error)
            }
            
        }
    }
    }
}



