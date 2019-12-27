//
//  VideoRecordViewController.swift
//  AVFoundationMaster
//
//  Created by xuanze on 2019/8/22.
//  Copyright © 2019 xuanze. All rights reserved.
//

import UIKit
import AVFoundation
class VideoRecordViewController: UIViewController {

    private var captureSession: AVCaptureSession!
    private var captureMovieFileOutput: AVCaptureMovieFileOutput!
    private var captureVideoPreviewLayer: AVCaptureVideoPreviewLayer!
    private var videoPath = ""
    private var timer: DispatchSourceTimer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.initRecord()
       
    }
    
    func initRecord() {
        self.captureSession = AVCaptureSession()
        if self.captureSession.canSetSessionPreset(.high) {
            self.captureSession.sessionPreset = .high
        }
        
        self.captureVideoPreviewLayer = AVCaptureVideoPreviewLayer(session: self.captureSession)
        self.captureVideoPreviewLayer.frame = CGRect(x: 10, y: 50, width: 355, height: 355)
        self.captureVideoPreviewLayer.videoGravity = .resizeAspectFill
        self.view.layer.addSublayer(self.captureVideoPreviewLayer)
        self.view.layer.masksToBounds = true
        
        self.captureMovieFileOutput = AVCaptureMovieFileOutput()
        let connection = self.captureMovieFileOutput.connection(with: .video)
        if connection != nil {
            if connection!.isVideoMirroringSupported {
                connection?.preferredVideoStabilizationMode = .auto
                connection?.videoOrientation = self.captureVideoPreviewLayer.connection!.videoOrientation
            }
        }
        
        if self.captureSession.canAddOutput(self.captureMovieFileOutput) {
            self.captureSession.addOutput(self.captureMovieFileOutput)
        }
    }
    
    
    @IBAction func beginRecord(_ sender: Any) {
        if FileManager.default.fileExists(atPath: videoPath) {
            do {
                try FileManager.default.removeItem(at: URL(fileURLWithPath: self.videoPath))
            } catch {
                print("删除失败 \(error.localizedDescription)")
            }
        }
        let result = self.setSessionInput()
        if result.success {
            self.captureSession.startRunning()
            self.startRecordSession()
        } else {
            self.captureSession.stopRunning()
            print("录制失败 \(result.error?.localizedDescription)")
        }
    }
    
    func setSessionInput() -> (success: Bool, error: Error?){
        let captureDevice = AVCaptureDevice.default(for: .video)
        if captureDevice != nil {
            do {
                // 给捕获会话类添加输入捕获设备
                let videoInput = try AVCaptureDeviceInput.init(device: captureDevice!)
                if self.captureSession.canAddInput(videoInput) {
                    self.captureSession.addInput(videoInput)
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
                if self.captureSession.canAddInput(audioInput) {
                    self.captureSession.addInput(audioInput)
                    return (true, nil)
                } else {
                    return (false, nil)
                }
            } catch {
                return (false, error)
            }
        }
        
        return (true, nil)
    }
    
    func startRecordSession() {
        let urlStr = NSTemporaryDirectory() + "haha.mov"
        print("视频想要缓存的地址\(urlStr)")
        
        if FileManager.default.fileExists(atPath: urlStr) {
            do {
                try FileManager.default.removeItem(at: URL(fileURLWithPath: urlStr))
            } catch {
                print("startRecordSession 删除文件失败 \(error.localizedDescription)")
            }
        }
        self.captureMovieFileOutput.startRecording(to: URL(fileURLWithPath: urlStr), recordingDelegate: self)
    }
    
    func startCount() {
        timer = DispatchSource.makeTimerSource(flags: [], queue: DispatchQueue.main)
        timer.schedule(deadline: .now(), repeating: 1)
        var time = 0
        timer.setEventHandler {
            time += 1
            print("录制时长\(time)")
            if time == 10 {
                print("录制时间限制在10s内")
                self.captureMovieFileOutput.stopRecording()
                self.captureSession.stopRunning()
                self.timer.cancel()
            }
        }
        timer.resume()
    }
    
    func compressVideoWithFileUrl(url: URL) {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd-HH:mm:ss"
        // 压缩后的文件路径
        self.videoPath = NSTemporaryDirectory() + "\(formatter.string(from: Date())).mov"
        
        // 先根据你传入的文件的路径穿件一个AVAsset
        let asset = AVAsset(url: url)
        //根据urlAsset创建AVAssetExportSession压缩类
        let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetLowQuality)
        exportSession?.determineCompatibleFileTypes(completionHandler: { (arry) in
            print(arry)
        })
        // 优化压缩，这个属性能使压缩的质量更好
        exportSession?.shouldOptimizeForNetworkUse = true
        exportSession?.outputURL = URL(fileURLWithPath: self.videoPath)
        // 导出的文件格式
        exportSession?.outputFileType = .mov
        
        print("被压缩后的presentName:\(exportSession?.presetName)")
        // 压缩的方法
        exportSession?.exportAsynchronously(completionHandler: {
            let exportStatus = exportSession!.status
            switch exportStatus {
            case .failed:
                print("压缩失败")
            case .completed:
                let data = NSData(contentsOfFile: self.videoPath)
                print("视频压缩后的大小\(Float((data?.length)!) / 1024 / 1024)")
            default:
                break
            }
        })
    }
    
    @IBAction func playRecord(_ sender: Any) {
        let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "VideoPlayViewController") as? VideoPlayViewController
        vc?.movieURL = URL(fileURLWithPath: self.videoPath)
        self.present(vc!, animated: true, completion: nil)
    }
    
    @IBAction func closeVC(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
}

extension VideoRecordViewController: AVCaptureFileOutputRecordingDelegate {
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        print("录制结束")
        print("视频缓存地址 \(outputFileURL)")
        if error == nil {
            self.compressVideoWithFileUrl(url: outputFileURL)
        }
    }
    
    func fileOutput(_ output: AVCaptureFileOutput, didStartRecordingTo fileURL: URL, from connections: [AVCaptureConnection]) {
        print("录制开始")
        self.startCount()
    }
}
