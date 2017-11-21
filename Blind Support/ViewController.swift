//
//  ViewController.swift
//  Blind Support
//
//  Created by Shivam Sharma on 11/4/17.
//  Copyright © 2017 ShivamSharma. All rights reserved.
//

import UIKit
import AVKit
import Vision
import AVFoundation

class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    var objectName = ""
    var detectionAccuracy = ""
    let synth = AVSpeechSynthesizer()
    var myUtterance = AVSpeechUtterance(string: "")
    var isUsingEmotionRecognition = false
    var model = try! VNCoreMLModel(for: Resnet50().model)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //here is where we start up the camera
        let captureSession = AVCaptureSession()
        //captureSession.sessionPreset = .photo
        
        guard let captureDevice = AVCaptureDevice.default(for: .video) else { return }
        guard let input = try? AVCaptureDeviceInput(device: captureDevice) else { return }
        captureSession.addInput(input)
        
        captureSession.startRunning()
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        view.layer.addSublayer(previewLayer)
        previewLayer.frame = view.frame
        
        
        let dataOutput = AVCaptureVideoDataOutput()
        dataOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
        captureSession.addOutput(dataOutput)
        
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(singleTapped))
        self.view.addGestureRecognizer(tapRecognizer)
        //tapRecognizer.delegate = self
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(doubleTapped))
        tap.numberOfTapsRequired = 2
        view.addGestureRecognizer(tap)
    }
    
    @objc func singleTapped() {
        self.synth.stopSpeaking(at: .immediate)
        self.myUtterance = AVSpeechUtterance(string: objectName)
        self.myUtterance.rate = 0.3
        self.synth.speak(self.myUtterance)
    }
    
    @objc func doubleTapped() {
        if (isUsingEmotionRecognition) {
            isUsingEmotionRecognition = false
        } else {
            isUsingEmotionRecognition = true
        }
    }
    
    // runs everytime the camera captures a frame
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        if (isUsingEmotionRecognition) {
            model = try! VNCoreMLModel(for: GenderNet().model)
        } else {
            model = try! VNCoreMLModel(for: Resnet50().model)
        }
        
        let request = VNCoreMLRequest(model: model) { (finishedReq, err) in
            // Check error
            
            //print(finishedReq.results)
            
            guard let results = finishedReq.results as? [VNClassificationObservation] else { return }
            guard let firstObservation = results.first else { return }
            
            self.objectName = firstObservation.identifier
            self.detectionAccuracy = "\(firstObservation.confidence)"
            //print(firstObservation.identifier, firstObservation.confidence)
            
        }
        
        try? VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:]).perform([request])
    }
    
}
