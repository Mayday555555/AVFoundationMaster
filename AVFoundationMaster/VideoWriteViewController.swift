//
//  VideoWriteViewController.swift
//  AVFoundationMaster
//
//  Created by xuanze on 2019/8/26.
//  Copyright © 2019 xuanze. All rights reserved.
//

import UIKit
import AVFoundation
import Photos
enum WriteViewVCRecordState:Int {
    case Init
    case PrepareRecord
    case Recording
    case Finish
    case Fail
}

class VideoWriteViewController: UIViewController {

    var dataDirectory: String?
    //队列
    var videoDataOutputQueue: DispatchQueue!
    var audioDataOutputQueue: DispatchQueue!
    var writingQueue: DispatchQueue!
    
    var avcaptureSession: AVCaptureSession!
    var writeState: WriteViewVCRecordState!
    var videoDataOutput: AVCaptureVideoDataOutput!
    var audioDataOutput: AVCaptureAudioDataOutput!
    
    var outputVideoFormatDescription: CMFormatDescription!
    var outputAudioFormatDescription: CMFormatDescription!

    var assetWriter: AVAssetWriter!
    var assetVideoInput: AVAssetWriterInput!
    var assetAudioInput: AVAssetWriterInput!
    
    var timer: DispatchSourceTimer!
    var canWrite = false
    
    var captureVideoPreviewLayer: AVCaptureVideoPreviewLayer!
    
    var assetCollectName = "录制视频"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.initRecord()
    }
    
    func initRecord() {
        self.dataDirectory = NSTemporaryDirectory() + "Movie.mp4"
        self.initDispatchQueue()
        
        self.avcaptureSession = AVCaptureSession()
        if avcaptureSession.canSetSessionPreset(.hd1280x720) {
            avcaptureSession.sessionPreset = .hd1280x720
        } else {
            print("sessionPreset 设置失败")
        }
        
        let result = self.setSessionInput()
        if result.success {
            self.writeState = WriteViewVCRecordState.PrepareRecord
            /*用来初始化AVCaptureSession  AVCaptureVideoDataOutput  AVCaptureAudioDataOutput 以及连接他们的 AVCaptureConnection */
            self.captureSessionAddOutputSession()
        } else {
            print("设置input失败")
        }
    }
    
    func initDispatchQueue() {
        videoDataOutputQueue = DispatchQueue(label: "CAPTURE_SESSION_QUEUE_VIDEO", qos: .userInteractive)
        audioDataOutputQueue = DispatchQueue(label: "CAPTURE_SESSION_QUEUE_AUDIO", qos: .default)
        writingQueue = DispatchQueue(label: "CAPTURE_SESSION_QUEUE_ASSET_WRITER", qos: .default)
    }
    
    func setSessionInput() -> (success: Bool, error: Error?){
        
        
        let captureDevice = AVCaptureDevice.default(for: .video)
        if captureDevice != nil {
            do {
                // 给捕获会话类添加输入捕获设备
                let videoInput = try AVCaptureDeviceInput.init(device: captureDevice!)
                if self.avcaptureSession!.canAddInput(videoInput) {
                    self.avcaptureSession!.addInput(videoInput)
                } else {
                    return (false, nil)
                }
            } catch {
                return (false, error)
            }
        } else {
            return (false, nil)
        }
        
        /*
         添加音频捕获设备
         */
        let audioDevice = AVCaptureDevice.default(for: .audio)
        if audioDevice != nil {
            do {
                let audioInput = try AVCaptureDeviceInput.init(device: audioDevice!)
                if self.avcaptureSession!.canAddInput(audioInput) {
                    self.avcaptureSession!.addInput(audioInput)
                } else {
                    return (false, nil)
                }
            } catch {
                return (false, error)
            }
        } else {
            return (false, nil)
        }
        
        return (true, nil)
    }
    
    func captureSessionAddOutputSession() {
        self.videoDataOutput = AVCaptureVideoDataOutput()
        self.videoDataOutput.videoSettings = nil
        self.videoDataOutput.alwaysDiscardsLateVideoFrames = false
        self.videoDataOutput.setSampleBufferDelegate(self, queue: self.videoDataOutputQueue)
        self.videoDataOutput.alwaysDiscardsLateVideoFrames = true//立即丢弃旧帧，节省内存，默认YES
        if self.avcaptureSession.canAddOutput(self.videoDataOutput) {
            self.avcaptureSession.addOutput(self.videoDataOutput)
        } else {
            print("addVideoOutput 失败")
        }
        
        self.audioDataOutput = AVCaptureAudioDataOutput()
        self.audioDataOutput.setSampleBufferDelegate(self, queue: self.audioDataOutputQueue)
        if self.avcaptureSession.canAddOutput(self.audioDataOutput) {
            self.avcaptureSession.addOutput(self.audioDataOutput)
        } else {
            print("addAudioOutput 失败")
        }
        
        self.captureVideoPreviewLayer = AVCaptureVideoPreviewLayer(session: self.avcaptureSession)
        self.captureVideoPreviewLayer.frame = CGRect(x: 10, y: 50, width: 355, height: 355)
        self.captureVideoPreviewLayer.videoGravity = .resizeAspectFill
        self.view.layer.addSublayer(self.captureVideoPreviewLayer)
        self.view.layer.masksToBounds = true
    }

    @IBAction func startRecord(_ sender: Any) {
        if FileManager.default.fileExists(atPath: self.dataDirectory ?? "") {
            do {
                let url = URL(fileURLWithPath: self.dataDirectory ?? "")
                try FileManager.default.removeItem(at: url)
            } catch {
                print("删除文件失败")
            }
        }
        
        self.avcaptureSession.startRunning()
        self.initAssetWriterInputAndOutput()
        self.startRunningSession()
    }
    
    func initAssetWriterInputAndOutput() {
        do {
            try self.assetWriter = AVAssetWriter(url: URL(fileURLWithPath: self.dataDirectory!), fileType: .mp4)
        } catch {
            print("assetWriter 初始化错误:\(error.localizedDescription)")
        }
        
        //AVVideoCodecKey 编码格式
        //AVVideoScalingModeKey 填充模式
        let outputSize = CGSize(width: 355, height: 355)
        let numPixels = outputSize.width * outputSize.height
        let bitPerPixels: CGFloat = 6.0//每像素比特
        let bitsPerSecond = numPixels * bitPerPixels
//        AVVideoAverageBitRateKey          视频尺寸*比率
//        AVVideoMaxKeyFrameIntervalKey     关键帧最大间隔，1为每个都是关键帧，数值越大压缩率越高
//        AVVideoExpectedSourceFrameRateKey 帧率
        let compressKeys = [AVVideoAverageBitRateKey: bitsPerSecond, AVVideoExpectedSourceFrameRateKey: 30, AVVideoMaxKeyFrameIntervalKey: 15, AVVideoProfileLevelKey: AVVideoProfileLevelH264BaselineAutoLevel] as [String : Any]
        let videoCompressionSettings = [AVVideoCodecKey: AVVideoCodecH264, AVVideoScalingModeKey: AVVideoScalingModeResizeAspectFill, AVVideoWidthKey: outputSize.height * 2, AVVideoHeightKey: outputSize.width * 2, AVVideoCompressionPropertiesKey: compressKeys] as [String : Any]
        
        if self.assetWriter.canApply(outputSettings: videoCompressionSettings, forMediaType: .video) {
            self.assetVideoInput  = AVAssetWriterInput(mediaType: .video, outputSettings: videoCompressionSettings)
            //expectsMediaDataInRealTime 必须设为yes，需要从capture session 实时获取数据
            self.assetVideoInput.expectsMediaDataInRealTime = true
            self.assetVideoInput.transform = CGAffineTransform(rotationAngle: CGFloat(Double.pi / 2.0))
            
            if self.assetWriter.canAdd(self.assetVideoInput) {
                self.assetWriter.add(self.assetVideoInput)
            } else {
                print("canAdd(self.assetVideoInput) 失败")
            }
        } else {
            print("assetWriter.canApplyvideo 失败")
        }
        
        let audioSettings = [AVFormatIDKey: kAudioFormatMPEG4AAC, AVEncoderBitRatePerChannelKey: 64000, AVSampleRateKey: 44100, AVNumberOfChannelsKey: 1]
        if self.assetWriter.canApply(outputSettings: audioSettings, forMediaType: .audio) {
            self.assetAudioInput = AVAssetWriterInput(mediaType: .audio, outputSettings: audioSettings)
            self.assetAudioInput.expectsMediaDataInRealTime = true
            if self.assetWriter.canAdd(self.assetAudioInput) {
                self.assetWriter.add(self.assetAudioInput)
            }else {
                print("canAdd(self.assetAudioInput) 失败")
            }
        } else {
            print("assetWriter.canApplyaudio 失败")
        }
        
        self.writeState = .Recording
    }
    
    func startRunningSession() {
        timer = DispatchSource.makeTimerSource(flags: [], queue: DispatchQueue.global(qos: .default))
        timer.schedule(deadline: .now(), repeating: 1)
        var time = 0
        timer.setEventHandler {
            time += 1
            print("录制时长\(time)")
            if time == 10 {
                print("录制时间限制在10s内")
                self.finishRecording()
                self.avcaptureSession.stopRunning()
                self.timer.cancel()
            }
        }
        timer.resume()
    }
    
    func finishRecording() {
        self.writeState = .Finish
        switch self.assetWriter.status {
        case .writing:
            self.writingQueue.async {
                self.assetWriter.finishWriting(completionHandler: {
                    
                    objc_sync_enter(self)
                    
                    let error = self.assetWriter!.error
                    if error != nil{
                        print("AssetWriterFinishError:\(error.debugDescription)")
                    } else {
                        print("成功")
                        self.saveVideoWithFilePath(filePath: self.dataDirectory!)
                    }
                    
                    objc_sync_exit(self)
                })
            }
        case .completed:
            print("assetWriter Status: completed")
        case .unknown:
            print("assetWriter Status: unknown")
        case .cancelled:
            print("assetWriter Status: cancelled")
        case .failed:
            print("assetWriter Status: failed")
        default:
            break
        }
    }
    
    func saveVideoWithFilePath(filePath: String) {
        let library = PHPhotoLibrary.shared()
        let mainQ = DispatchQueue.main
        mainQ.async {
            var assetID = ""
            var assetCollectionID = ""
            do {
                try library.performChangesAndWait {
                    assetID = PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: URL(fileURLWithPath: filePath))?.placeholderForCreatedAsset?.localIdentifier ?? ""
                    print("视频标示：\(assetID)")
                }
            } catch {
                print("performChangesAndWait error: \(error.localizedDescription)")
            }
            
            var collectionAsset: PHAssetCollection?
            let assetCollections = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .albumRegular, options: nil)
            for i in 0..<assetCollections.count {
                let collect = assetCollections[i]
                if collect.localizedTitle == self.assetCollectName {
                    collectionAsset = collect
                    break
                }
            }
            
            if collectionAsset == nil {
                do {
                    try library.performChangesAndWait {
                        assetCollectionID = PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: self.assetCollectName).placeholderForCreatedAssetCollection.localIdentifier
                        print("相册创建标示：\(assetCollectionID)")
                        
                        collectionAsset = PHAssetCollection.fetchAssetCollections(withLocalIdentifiers: [assetCollectionID], options: nil).firstObject
                    }
                } catch {
                    print("performChangesAndWait error: \(error.localizedDescription)")
                }
            }
            
            do {
                try library.performChangesAndWait {
                    let request = PHAssetCollectionChangeRequest(for: collectionAsset!)
                    request?.addAssets(PHAsset.fetchAssets(withLocalIdentifiers: [assetID], options: nil))
                }
            } catch {
                print("performChangesAndWait error: \(error.localizedDescription)")
            }
            
        }
    }
    
    @IBAction func playVideo(_ sender: Any) {
        let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "VideoPlayViewController") as? VideoPlayViewController
        vc?.movieURL = URL(fileURLWithPath: self.dataDirectory!)
        self.present(vc!, animated: true, completion: nil)
    }
    
    @IBAction func close(_ sender: Any) {
        self.dismiss(animated: true) {
            
        }
    }
}

extension VideoWriteViewController: AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        let formatDescription = CMSampleBufferGetFormatDescription(sampleBuffer)
        if connection == self.videoDataOutput.connection(with: .video) {
            if self.outputVideoFormatDescription == nil {
                self.outputVideoFormatDescription = formatDescription
            } else {
                self.outputVideoFormatDescription = formatDescription
                objc_sync_enter(sampleBuffer)
                self.appendSampleBuffer(sampleBuffer: sampleBuffer, mediaType: .video)
                objc_sync_exit(sampleBuffer)
            }
        } else if connection == self.audioDataOutput.connection(with: .audio) {
            self.outputAudioFormatDescription = formatDescription
            objc_sync_enter(sampleBuffer)
            self.appendSampleBuffer(sampleBuffer: sampleBuffer, mediaType: .audio)
            objc_sync_exit(sampleBuffer)
        }
    }
    
    func appendSampleBuffer(sampleBuffer: CMSampleBuffer, mediaType: AVMediaType) {
        objc_sync_enter(sampleBuffer)
        if self.writeState.rawValue < WriteViewVCRecordState.Recording.rawValue {
            print("not ready")
            return
        }
        objc_sync_exit(sampleBuffer)
        
        
        self.writingQueue.async {
            objc_sync_enter(sampleBuffer)
            if self.writeState.rawValue > WriteViewVCRecordState.Recording.rawValue {
                print(" > WriteViewVCRecordState.Recording.rawValue ")
                return
            }
            objc_sync_exit(sampleBuffer)
            
            if !self.canWrite && mediaType == .video {
                self.assetWriter.startWriting()
                self.assetWriter.startSession(atSourceTime: CMSampleBufferGetPresentationTimeStamp(sampleBuffer))
                self.canWrite = true
            }
            
            let input: AVAssetWriterInput = (mediaType == AVMediaType.video) ? self.assetVideoInput : self.assetAudioInput
            if input.isReadyForMoreMediaData {
                let success = input.append(sampleBuffer)
                if !success {
                    self.finishRecording()
                    let error = self.assetWriter.error
                    print("input error: \(error.debugDescription)")
                }
            } else {
                print("\(mediaType) input not ready for more media data, dropping buffer")
            }
        }
    }
}
