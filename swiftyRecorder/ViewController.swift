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

class ViewController: UIViewController, ARSCNViewDelegate, ARSessionDelegate, AVCaptureAudioDataOutputSampleBufferDelegate, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    @IBOutlet var sceneView: ARSCNView!
    var fileURL: URL!
    var dataFileURL: URL!
    var session: AVCaptureSession!
    private var audioConnection: AVCaptureConnection!
    private var previewLayer: AVCaptureVideoPreviewLayer?
    var fileWriter: AVAssetWriter!
    var videoInput: AVAssetWriterInput!
    var audioInput: AVAssetWriterInput!
    private var isRecordingSessionStarted: Bool = false
    var adaptor: AVAssetWriterInputPixelBufferAdaptor!
    var recordLabel: UILabel = UILabel()
    var firstFram2e: TimeInterval!
    var counter: Int = 0
    var running:Bool = false
    let fileManager = FileManager.default
    let sessionQueue: DispatchQueue = DispatchQueue(label: "sampleBuffer", attributes: [])
    
    
    @IBAction func swipe_up(_ sender: Any) {
        
        if self.running {
            self.session.stopRunning()
            self.videoInput.markAsFinished()
            self.audioInput.markAsFinished()
            
            self.fileWriter.finishWriting {
                DispatchQueue.main.async {
                    self.recordLabel.text = ""
                }
                
                UISaveVideoAtPathToSavedPhotosAlbum(self.fileWriter.outputURL.path, nil, nil, nil);
                
                let vc = UIActivityViewController(activityItems: [self.dataFileURL, self.fileURL], applicationActivities: [])
                self.present(vc, animated: true, completion: nil)
                
                self.running = false
                self.isRecordingSessionStarted = false
            }
        } else {
            DispatchQueue.main.async {
                self.recordLabel.text = "recording.."
            }
            
            let timestamp = ISO8601DateFormatter().string(from: Date())
            do {
                self.fileURL = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true).appendingPathComponent("video-" + timestamp + ".mp4")
                self.dataFileURL = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true).appendingPathComponent("video-blendshapes" + timestamp + ".csv")
            } catch {
                print(error)
            }
            
            
            
            self.fileManager.createFile(atPath: self.dataFileURL.path, contents: nil)
            self.counter = 0
            self.firstFram2e = nil
            
            do {
                self.fileWriter = try AVAssetWriter(outputURL: self.fileURL, fileType: AVFileType.mp4)
            } catch {
                print(error)
            }
            
            self.fileWriter!.movieFragmentInterval = kCMTimeInvalid
            self.fileWriter!.shouldOptimizeForNetworkUse = false
            
            let videoOutputSettings: Dictionary<String, Any> = [
                AVVideoCodecKey : AVVideoCodecType.h264,
                AVVideoWidthKey : 1280,
                AVVideoHeightKey : 720
            ];
            
            self.videoInput = AVAssetWriterInput(mediaType: AVMediaType.video, outputSettings: videoOutputSettings)
            
            self.adaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: self.videoInput)
            
            self.videoInput.expectsMediaDataInRealTime = true
            self.fileWriter.add(self.videoInput)
            
            let audioOutputSettings: Dictionary<String, Any> = [
                AVFormatIDKey : kAudioFormatMPEG4AAC,
                AVNumberOfChannelsKey : 2,
                AVSampleRateKey : 44100.0,
                AVEncoderBitRateKey : 192000
            ]
            
            self.audioInput = AVAssetWriterInput(mediaType: AVMediaType.audio, outputSettings: audioOutputSettings)
            self.audioInput.expectsMediaDataInRealTime = true
            self.fileWriter.add(self.audioInput)
            
            self.session.startRunning()
            self.running = true
        }
        
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        self.sceneView.delegate = self
        
        self.sceneView.preferredFramesPerSecond = 60
        
        // Show statistics such as fps and timing information
        self.sceneView.showsStatistics = true
        
        self.session = AVCaptureSession()
        self.previewLayer = AVCaptureVideoPreviewLayer(session: self.session)
        self.previewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
        self.previewLayer?.frame = self.view.bounds
        self.view.layer.addSublayer(self.previewLayer!)
        
        self.sceneView.frame = self.view.bounds
        self.sceneView.backgroundColor = UIColor.clear
        
        
        self.session.beginConfiguration()
        
        var mic_input: AVCaptureDeviceInput!
        let mic = AVCaptureDevice.default(for: .audio)
        do {
            mic_input = try AVCaptureDeviceInput(device: mic!)
        } catch {
            print(error)
        }
        self.session.addInput(mic_input)
        
        let audio_output = AVCaptureAudioDataOutput()
        audio_output.setSampleBufferDelegate(self, queue: self.sessionQueue)
        self.session.addOutput(audio_output)
        self.audioConnection = audio_output.connection(with: .audio)
        
        self.session.commitConfiguration()
        
        self.recordLabel.frame = CGRect(x: 10, y: 10, width: 100, height: 100)
        self.recordLabel.text = ""
        self.recordLabel.textColor = .red
        
        self.sceneView.addSubview(self.recordLabel)
        
    }
    
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        if self.running  {
            sessionQueue.async {
                if !self.isRecordingSessionStarted {
                    let presentationTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
                    self.fileWriter.startWriting()
                    self.fileWriter?.startSession(atSourceTime: presentationTime)
                    self.isRecordingSessionStarted = true
                    return
                }
                
                if connection == self.audioConnection {
                    self.audioInput.append(sampleBuffer)
                }
            }
        }
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let configuration = ARFaceTrackingConfiguration()
        
        self.sceneView.session.run(configuration)
        self.sceneView.session.delegate = self
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.sceneView.session.pause()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
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
                
                
                do {
                    
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



