//
//  VideoPlayViewController.swift
//  AVFoundationMaster
//
//  Created by xuanze on 2019/8/22.
//  Copyright © 2019 xuanze. All rights reserved.
//

import UIKit
import AVFoundation
class VideoPlayViewController: UIViewController {

    @IBOutlet weak var videoTotalTime: UILabel!
    @IBOutlet weak var videoPlayTime: UILabel!
    @IBOutlet weak var labelCache: UILabel!
    
    public var movieURL:URL!
    private var avPlayerItem:AVPlayerItem!
    private var avPlayer: AVPlayer!
    private var avPlayerLayer: AVPlayerLayer!
    private var playbackTimerObserver:Any!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.initPlay()
    }
    
    deinit {
        self.avPlayerItem.removeObserver(self, forKeyPath: "status", context: nil)
        self.avPlayerItem.removeObserver(self, forKeyPath: "loadedTimeRanges", context: nil)
        self.avPlayer.removeTimeObserver(self.playbackTimerObserver)
        
        self.avPlayer.pause()
        self.avPlayerItem = nil
        self.avPlayer = nil
    }
    
    private func initPlay() {
        self.avPlayerItem = AVPlayerItem(url: self.movieURL)
        self.avPlayer = AVPlayer(playerItem: self.avPlayerItem)
        self.avPlayerLayer = AVPlayerLayer(player: self.avPlayer)
        
        self.avPlayerLayer.frame = CGRect(x: 10, y: 100, width: 355, height: 200)
        self.view.layer.addSublayer(self.avPlayerLayer)
        
        self.addObserverWithAVPlayerItem()
    }
    
    func addObserverWithAVPlayerItem() {
        //通过kvo监听AVPlayerItem的状态和缓存进度
        self.avPlayerItem.addObserver(self, forKeyPath: "status", options: .new, context: nil)
        self.avPlayerItem.addObserver(self, forKeyPath: "loadedTimeRanges", options: .new, context: nil)
        //监听当前播放进度
        self.playbackTimerObserver = self.avPlayer.addPeriodicTimeObserver(forInterval: CMTimeMake(value: 1, timescale: 10), queue: DispatchQueue.main) {[weak self] (time) in
            let currentPlayTime = (self?.avPlayerItem!.currentTime().value)! / CMTimeValue((self?.avPlayerItem)!.currentTime().timescale)
            self?.videoPlayTime.text = "已播放时间\(currentPlayTime)"
        }
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        let item = object as? AVPlayerItem
        if keyPath == "status" {
            print(change)
            if let itemStatus = change?[NSKeyValueChangeKey.newKey] as? Int{
                switch itemStatus {
                case AVPlayerItem.Status.unknown.rawValue:
                    print("unknown")
                case AVPlayerItem.Status.readyToPlay.rawValue:
                    print("准备好播放")
                    let duration = self.avPlayerItem.duration
                    self.videoTotalTime.text = "视频总时长\(CMTimeGetSeconds(duration))"
                    self.avPlayer.play()
                case AVPlayerItem.Status.failed.rawValue:
                    if item != nil {
                        print("准备发生错误:\(item!.error)")
                    }
                default:
                    break
                }
            }
        } else if keyPath == "loadedTimeRanges" {
            let timeInterval = self.alreadyCacheVideoProgress()
            self.labelCache.text = String(format: "缓存进度%.2f", timeInterval)
        }
    }
    
    func alreadyCacheVideoProgress() -> Double {
        // 先获取到它的缓存的进度
        let loadedTimeRanges = self.avPlayerItem?.loadedTimeRanges
        let timeRange = loadedTimeRanges?.first?.timeRangeValue// 获取缓冲区域
        // CMTimeRange 结构体 start duration 表示起始位置 和 持续时间
        let startSeconds = CMTimeGetSeconds((timeRange?.start)!)
        let durationSeconds = CMTimeGetSeconds((timeRange?.duration)!)
        let timeInterval = startSeconds + durationSeconds// 计算缓冲总进度
        return timeInterval
    }
    
    @IBAction func onBtnBackTap(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    

}
