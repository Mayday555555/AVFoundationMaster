//
//  AVAudioRecorderController.swift
//  AVFoundationMaster
//
//  Created by xuanze on 2019/8/20.
//  Copyright © 2019 xuanze. All rights reserved.
//

import UIKit
import AVFoundation
class AVAudioRecorderController: UIViewController {

    //分贝值
    @IBOutlet weak var labelPeakPower: UILabel!
    @IBOutlet weak var labelAveragePower: UILabel!
    @IBOutlet weak var labelRecordTime: UILabel!
    @IBOutlet weak var btnStartRecord: UIButton!
    @IBOutlet weak var btnEndRecord: UIButton!
    @IBOutlet weak var btnPlayRecord: UIButton!
    @IBOutlet weak var labelState: UILabel!
    
    public var filePath = ""
    private var destPath: URL!
    private var avAudioRecoder: AVAudioRecorder!
    private var timer: DispatchSourceTimer!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.initPlay()
        
    }
    
    func initPlay() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playAndRecord)
        } catch {
            print("session init error:\(error.localizedDescription)")
        }
        
        do {
            try session.setActive(true, options: .notifyOthersOnDeactivation)
        } catch  {
            print("session active error:\(error.localizedDescription)")
        }
        
        labelState.text = "准备录制"
        filePath = NSTemporaryDirectory() + "memo.caf"
        do {
            self.avAudioRecoder =  try AVAudioRecorder(url: URL(fileURLWithPath: filePath), settings: [AVFormatIDKey:kAudioFormatAppleIMA4,AVSampleRateKey: 44100.0,  AVNumberOfChannelsKey: 1, AVEncoderAudioQualityKey: kRenderQuality_Medium])
        } catch {
            print("audioRecoder init error:\(error.localizedDescription)")
        }
        
        if self.avAudioRecoder != nil {
            self.avAudioRecoder.delegate = self
            self.avAudioRecoder.isMeteringEnabled = true
            self.avAudioRecoder.prepareToRecord()
        }
        
    }
    

    @IBAction func onBtnStartRecordTap(_ sender: Any) {
        self.labelState.text = "录制中"
        if !self.avAudioRecoder.isRecording {
            //开启定时器
            timer = DispatchSource.makeTimerSource(flags: [], queue: DispatchQueue.main)
            timer.schedule(deadline: .now(), repeating: 1)
            var time = 0
            
            timer.setEventHandler {
                time += 1
                if time <= 10 {
                    //小于10s更新录制时间和分贝
                    DispatchQueue.main.async {
                        self.updateRecordTimeAndPower(time: time)
                    }
                } else {
                    //停止录音
                    self.stopRecord()
                }
                
            }
            self.timer.resume()
            self.avAudioRecoder.record()
        }
    }
    
    func updateRecordTimeAndPower(time: Int) {
        labelRecordTime.text = "\(time)秒"
        
        self.avAudioRecoder.updateMeters()
        let peakPower = self.avAudioRecoder.peakPower(forChannel: 0)
        let averPower = self.avAudioRecoder.averagePower(forChannel: 0)
        labelPeakPower.text = "分贝值\(peakPower)"
        labelAveragePower.text = "平均分贝值\(averPower)"
    }
    
    func stopRecord() {
        self.timer.cancel()
        self.avAudioRecoder.stop()
        
        self.labelState.text = "录制结束"
        self.saveRecordingName(name: "TestAudio") { (save, error) in
            if save {
                print("保存视频成功")
            } else {
                print("保存视频失败 error: \(error)")
            }
        }
    }
    
    func saveRecordingName(name: String, block:(_ save: Bool, _ error: String)->()) {
        let timesTamp = NSDate.timeIntervalSinceReferenceDate
        let fileName = "\(name)-\(timesTamp).m4a"
        
        let docDir = self.documentsDirectory()
        let destPath = docDir + "/\(fileName)"
        print(destPath)
        print(self.filePath)
        let destUrl = URL(fileURLWithPath: destPath)
        
        var errorStr = ""
        do {
            try FileManager.default.moveItem(at: URL(fileURLWithPath: self.filePath), to: destUrl)
        } catch  {
            errorStr = error.localizedDescription
        }
        
        if errorStr.isEmpty {
            self.destPath = destUrl
            block(true, errorStr)
            self.avAudioRecoder.prepareToRecord()
        } else {
            block(false, errorStr)
        }
    }
    
    func documentsDirectory() -> String {
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        print(paths)
        return paths[0]
    }
    
    @IBAction func onBtnEndRecordTap(_ sender: Any) {
        self.stopRecord()
    }
    
    @IBAction func onBtnPlayRecordTap(_ sender: Any) {
        let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "AVAudioPlayerViewController") as? AVAudioPlayerViewController
        vc?.filePath = destPath
        self.present(vc!, animated: true, completion: nil)
    }
    
    @IBAction func onBtnBackTap(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
}

extension AVAudioRecorderController: AVAudioRecorderDelegate {
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        print("录制结束")
    }
    
    func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        print("编码出错")
    }
}
