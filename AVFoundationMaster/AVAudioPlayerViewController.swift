//
//  AVAudioPlayerViewController.swift
//  AVFoundationMaster
//
//  Created by xuanze on 2019/8/19.
//  Copyright © 2019 xuanze. All rights reserved.
//

import UIKit
import AVFoundation
class AVAudioPlayerViewController: UIViewController {

    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var labelPeakDecibel: UILabel!
    @IBOutlet weak var labelAverageDecibel: UILabel!
    @IBOutlet weak var btnPlayAudio: UIButton!
    public var filePath: URL!
    private var avAudioPlayer: AVAudioPlayer!
    private var isPlay = false
    private var cadisplayerlink: CADisplayLink!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let session = AVAudioSession.sharedInstance()
        print(session.category)
        do {
            try session.setCategory(.playback)
        } catch {
            print("Category error:\(error)")
        }
        
        do {
            try session.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("Active error: \(error)")
        }
        print("\(session.isOtherAudioPlaying)")
        
        var urlPath: URL!
        if filePath != nil {
            urlPath = filePath
        } else {
            if let path = Bundle.main.path(forResource: "薛之谦-像风一样.mp3", ofType: nil) {
                urlPath = URL(fileURLWithPath: path)
            }
        }
        
        do {
            try avAudioPlayer = AVAudioPlayer(contentsOf: urlPath)
        } catch {
            print("AVAudioPlayer init error\(error)")
        }
        
        if avAudioPlayer != nil {
            print("初始化成功")
            print("音频时长\(avAudioPlayer.duration)")
            avAudioPlayer.delegate = self
             // 是否能设置rate属性，只有这个属性设置成YES了才能设置rate属性，并且这些属性都设置在prepareToPlay方法调用之前
            avAudioPlayer.enableRate = true
            // 允许使用立体声播放声音 如果为-1.0则完全左声道，如果0.0则左右声道平衡，如果为1.0则完全为右声道
            avAudioPlayer.pan = 0
            avAudioPlayer.isMeteringEnabled = true
            // 准备播放，这个方法可以不执行，但执行的话可以降低播放器play方法和你听到声音之间的延时
            avAudioPlayer.prepareToPlay()
        } else {
            print("初始化失败")
        }
        
        self.view.backgroundColor = UIColor.white
    }
    
    deinit {
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if cadisplayerlink != nil {
            cadisplayerlink.invalidate()
        }
        if avAudioPlayer.isPlaying {
            avAudioPlayer.stop()
        }
        avAudioPlayer = nil
    }
    
    @IBAction func playAudio(_ sender: Any) {
        isPlay = !isPlay
        if isPlay {
            avAudioPlayer.play()
            if avAudioPlayer.isPlaying {
                btnPlayAudio.setTitle("暂停播放", for: .normal)
                //开启定时器更新播放进度
                self.cadisplayerLinkStartPlayerAudio()
            }
        } else {
            avAudioPlayer.pause()
            btnPlayAudio.setTitle("播放本地音频", for: .normal)
            
        }
    }
    
    func cadisplayerLinkStartPlayerAudio () {
        if cadisplayerlink == nil {
            cadisplayerlink = CADisplayLink(target: self, selector: #selector(updateProgress))
            if #available(iOS 10.0, *) {
                cadisplayerlink.preferredFramesPerSecond = 5
            } else {
                cadisplayerlink.frameInterval = 5
            }
            cadisplayerlink.add(to: RunLoop.current, forMode: .common)
        }
    }
    
    @objc func updateProgress() {
        print("currentTime: \(avAudioPlayer.currentTime)")
        print("deviceCurrentTime: \(avAudioPlayer.deviceCurrentTime)")
        
        progressView.setProgress(Float(avAudioPlayer.currentTime / avAudioPlayer.duration), animated: true)
    }
    
    @IBAction func getDecibel(_ sender: Any) {
        avAudioPlayer.updateMeters()
        labelPeakDecibel.text = "指定频道分贝值:\(avAudioPlayer.peakPower(forChannel: 0))"
        labelAverageDecibel.text = "平均分贝值：\(avAudioPlayer.averagePower(forChannel: 0))"
    }
    
    @IBAction func onBtnBackTap(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
}

extension AVAudioPlayerViewController: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        print("播放完成")
    }
    
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        print("解码出错|\(error)")
    }
}
