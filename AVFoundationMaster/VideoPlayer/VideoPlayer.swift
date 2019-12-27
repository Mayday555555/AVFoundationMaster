//
//  VideoPlayer.swift
//
//  Created by 陈铉泽 on 2019/3/19.
//

import UIKit
import AVFoundation

@objc protocol VideoPlayerDelegate {
    func enterFullScreen()
    func quitFullScreen()
    func canAutororate(canrorate: Bool)
    func popController()
}

enum VideoPlayStatus {
    case PlayerStatusFailed
    case PlayerStatusReadyToPlay
    case PlayerStatusUnknown
    case PlayerStatusBuffering
    case PlayerStatusPlaying
    case PlayerStatusStopped
}

enum VideoLayerVideoGravity {
    case LayerVideoGravityResizeAspect
    case LayerVideoGravityResizeAspectFill
    case LayerVideoGravityResize
}

/// 视频播放器
class VideoPlayer: UIView {
    //加载动画
    private var activityIndeView:UIActivityIndicatorView?
    //返回按钮
    private var btnBack = UIButton()
    //底部控制视图
    private var controlView = VideoControlView()
    //暂停和播放视图
    private var pauseOrPlayView = VideoPauseAndPlayView()
    //原始约束
    private var oldConstraints: [NSLayoutConstraint]?
    //添加标题
    // 状态栏高
    private let StatusBarHeight: CGFloat   = UIApplication.shared.statusBarFrame.size.height
    
    override final class var layerClass: AnyClass {
        return AVPlayerLayer.self
    }
    
    
    //AVPlayer
    private var player: AVPlayer? {
        set {
            self.playerLayer.player = newValue
        }
        get {
            return self.playerLayer.player
        }
    }
    private var playerLayer: AVPlayerLayer {
        return self.layer as! AVPlayerLayer
    }
    
    private var playbackTimerObserver:Any!
    //AVPlayer的播放item
    private var item: AVPlayerItem?
    //总时长
    private var totalTime = CMTime()
    //当前时间
    private var currentTime = CMTime()
    //资产AVURLAsset
    private var anAsset: AVAsset?
    //播放器Playback Rate
    private var rate: CGFloat {
        set {
            self.player?.rate = Float(newValue)
        }
        get {
            return CGFloat((self.player?.rate)!)
        }
    }
    //播放状态
    private var status: VideoPlayStatus!
    //videoGravity设置屏幕填充模式，（只写）
    private var mode: VideoLayerVideoGravity!
    //是否正在播放
    private var isPlaying = false
    //是否全屏
    private var isFullScreen = false
    //是否已经加载了
    private var isLoad = false
    //播放按钮状态 true正在播放 false暂停
    private var btnState = false
    //当前播放url
    private var url = NSURL()
    
    private var count = 0
    //横竖屏的时候过渡动画时间，设置为0.0则是无动画
    private var kTransitionTime = 0.2
    private var viewFrame = CGRect()
    private var parentView: UIView?
    public weak var delegate: VideoPlayerDelegate? = nil
    
    private var fullScreenPlayer: VideoPlayer?
    private var fullScreenVC: UIViewController?
    //防止一个界面有多个视频播放器，全屏缩小之后混淆了
    public var isShow = false
    
    init(frame: CGRect, url: NSURL) {
        super.init(frame: frame)
        self.setupUI()
        self.setupPlayerUI()
        self.url = url
    }
    
    init(frame: CGRect, asset: AVAsset) {
        super.init(frame: frame)
        self.setupUI()
        self.setupPlayerUI()
        self.anAsset = asset
        self.setupPlayerWithAsset(asset: self.anAsset!)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //MARK: UI初始化
    private func setupUI() {
        self.backgroundColor = UIColor.black
        activityIndeView = UIActivityIndicatorView(style: .whiteLarge)
        activityIndeView?.hidesWhenStopped = true
        pauseOrPlayView = VideoPauseAndPlayView(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
        pauseOrPlayView.backgroundColor = UIColor.clear
        pauseOrPlayView.delegate = self
        controlView = VideoControlView()
        controlView.backgroundColor = UIColor.clear
        //        controlView.tapGes.require(toFail: (self.pauseOrPlayView.btnImage.gestureRecognizers?.first)!)
        controlView.delegete = self
        btnBack.setImage(UIImage(named: "nav_icon_back_white"), for: .normal)
        btnBack.addTarget(self, action: #selector(self.onBtnBackTap(btn:)), for: .touchUpInside)
    }
    
    public func setupSuperViewFrame() {
        parentView = (self.superview)!
        viewFrame = self.frame
    }
    
    ///隐藏返回按钮
    public func setupBtnBackHidden() {
        btnBack.isHidden = true
    }
    
    private func setupPlayerUI() {
        self.addSubview(self.activityIndeView!)
        self.activityIndeView?.snp.makeConstraints { (maker) in
            maker.height.equalTo(80)
            maker.center.equalTo(self)
        }
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(self.handleTapAction(ges:)))
        tap.delegate = self
        self.addGestureRecognizer(tap)
        
        self.addSubview(self.pauseOrPlayView)
        self.pauseOrPlayView.snp.makeConstraints { (maker) in
            maker.edges.equalTo(self)
        }
        
        self.addSubview(self.controlView)
        self.controlView.snp.makeConstraints { (maker) in
            maker.left.right.bottom.equalTo(self)
            maker.height.equalTo(45)
        }
        
        self.addSubview(self.btnBack)
        self.btnBack.snp.makeConstraints { (maker) in
            maker.left.equalToSuperview()
            maker.top.equalTo(StatusBarHeight)
            maker.height.width.equalTo(44)
        }
        
        self.initTimeLabels()
        self.layoutIfNeeded()
    }
    
    @objc private func onBtnBackTap(btn: UIButton) {
        if isFullScreen {
            self.getLarge(controlView: self.controlView, button: UIButton())
        } else {
            self.delegate?.popController()
        }
    }
    
    @objc private func handleTapAction(ges: UITapGestureRecognizer) {
        self.setSubViewIsHidden(hide: false)
        count = 0
    }
    
    private func setSubViewIsHidden(hide: Bool) {
        self.controlView.isHidden = hide
        self.pauseOrPlayView.isHidden = hide
    }
    
    private func initTimeLabels() {
        self.controlView.currentTime = "00:00"
        self.controlView.totalTime = "00:00"
    }
    
    // MARK:播放初始化
    private func assetWithURL(url: NSURL) {
        let options = [AVURLAssetPreferPreciseDurationAndTimingKey: true]
        self.anAsset = AVURLAsset(url: url as URL, options: options)
        let keys = ["duration"]
        self.anAsset?.loadValuesAsynchronously(forKeys: keys, completionHandler: {
            var error: NSError? = nil
            let tracksStatus = self.anAsset?.statusOfValue(forKey: "duration", error: &error)
            //            AVKeyValueStatus
            //            case unknown
            //
            //            case loading
            //
            //            case loaded
            //
            //            case failed
            //
            //            case cancelled
            switch tracksStatus?.rawValue {
            case 0:
                print("AVKeyValueStatusUnknown未知")
            case 1:
                print("AVKeyValueStatusLoading正在加载")
            case 2:
                DispatchQueue.main.async(execute: {
                    if self.anAsset?.duration != nil {
                        if !CMTIME_IS_INDEFINITE((self.anAsset?.duration)!) {
                            let second = (self.anAsset?.duration.value)! / CMTimeValue((self.anAsset?.duration.timescale)!)
                            self.controlView.totalTime = self.convertTime(second: CGFloat(second))
                            self.controlView.minValue = 0
                            self.controlView.maxValue = CGFloat(second)
                        }
                    }
                    
                })
            case 3:
                print("AVKeyValueStatusFailed失败,请检查网络,或查看plist中是否添加App Transport Security Settings")
            case 4:
                print("AVKeyValueStatusCancelled取消")
            default:
                break
            }
        })
        self.setupPlayerWithAsset(asset: (self.anAsset)!)
    }
    
    private func setupPlayerWithAsset(asset: AVAsset) {
        self.item = AVPlayerItem(asset: asset)
        self.player = AVPlayer(playerItem: self.item)
        self.playerLayer.displayIfNeeded()
        self.playerLayer.videoGravity = .resizeAspect
        self.addPeriodicTimeObserver()
        self.addKVO()
        self.addNotificationCenter()
    }
    
    //MARK: Tracking time,跟踪时间的改变
    private func addPeriodicTimeObserver() {
        self.playbackTimerObserver = self.player?.addPeriodicTimeObserver(forInterval: CMTimeMake(value: 1, timescale: 1), queue: nil) {[weak self] (time) in
            self?.controlView.value = CGFloat((self?.item?.currentTime().value)! / CMTimeValue((self?.item?.currentTime().timescale)!))
            if !CMTIME_IS_INDEFINITE((self?.anAsset?.duration)!) {
                self?.controlView.currentTime = (self?.convertTime(second: (self?.controlView.value)!))!
            }
            if (self?.count)! >= 5 {
                self?.setSubViewIsHidden(hide: true)
            }else {
                self?.setSubViewIsHidden(hide: false)
            }
            self?.count += 1
        }
    }
    
    //MARK: KVO
    private func addKVO() {
        //监听状态属性
        self.item?.addObserver(self, forKeyPath: "status", options: .new, context: nil)
        //监听网络加载情况属性
        self.item?.addObserver(self, forKeyPath: "loadedTimeRanges", options: .new, context: nil)
        //监听播放的区域缓存是否为空
        self.item?.addObserver(self, forKeyPath: "playbackBufferEmpty", options: .new, context: nil)
        //缓存可以播放的时候调用
        self.item?.addObserver(self, forKeyPath: "playbackLikelyToKeepUp", options: .new, context: nil)
        //监听暂停或者播放中
        self.item?.addObserver(self, forKeyPath: "rate", options: .new, context: nil)
    }
    
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "status" {
            if let itemStatus = change?[NSKeyValueChangeKey.newKey] as? AVPlayerItem.Status {
                switch itemStatus {
                case .unknown:
                    self.status = .PlayerStatusUnknown
                case .readyToPlay:
                    self.status = .PlayerStatusReadyToPlay
                case .failed:
                    self.status = .PlayerStatusFailed
                default:
                    break
                }
            }
        } else if keyPath == "loadedTimeRanges" {//监听播放器的下载进度
            let loadedTimeRanges = self.item?.loadedTimeRanges
            let timeRange = loadedTimeRanges?.first?.timeRangeValue// 获取缓冲区域
            let startSeconds = CMTimeGetSeconds((timeRange?.start)!)
            let durationSeconds = CMTimeGetSeconds((timeRange?.duration)!)
            let timeInterval = startSeconds + durationSeconds// 计算缓冲总进度
            let duration = self.item?.duration
            let totalDuration  = CMTimeGetSeconds(duration!)
            //缓存值
            self.controlView.bufferValue = CGFloat(timeInterval / totalDuration)
        } else if keyPath == "playbackBufferEmpty"{//监听播放器在缓冲数据的状态
            self.status = .PlayerStatusBuffering
            if !(self.activityIndeView?.isAnimating)! {
                self.activityIndeView?.startAnimating()
            }
        } else if keyPath == "playbackLikelyToKeepUp"{
            print("缓冲达到可播放")
            self.isLoad = true
            self.activityIndeView?.stopAnimating()
            if btnState {
                self.play()
            }
        } else if keyPath == "rate"{//当rate==0时为暂停,rate==1时为播放,当rate等于负数时为回放
            let rate: Int = change?[NSKeyValueChangeKey.newKey] as! Int
            print("keyPath rate \(rate)")
            if rate == 0 {
                isPlaying = false
                status = .PlayerStatusStopped
            } else {
                isPlaying = true
                status = .PlayerStatusPlaying
            }
            
        }
    }
    
    private func seekToTime(time: CMTime)  {
        self.item?.seek(to: time)
    }
    
    //MARK:播放 暂停 停止
    ///一进界面马上播放视频
    public func nowPlay() {
        self.pauseOrPlayView(view: self.pauseOrPlayView)
    }
    
    public func play() {
        if self.player != nil {
            self.isPlaying = true
            self.pauseOrPlayView.setupPlay(isPlay: true)
            self.player?.play()
            self.delegate?.canAutororate(canrorate: true)
        }
    }
    
    public func pause() {
        if self.player != nil {
            self.isPlaying = false
            self.pauseOrPlayView.setupPlay(isPlay: false)
            self.player?.pause()
//            self.delegate?.canAutororate(canrorate: false)
        }
    }
    
    public func stop() {
        self.item?.removeObserver(self, forKeyPath: "status")
        self.item?.removeObserver(self, forKeyPath: "loadedTimeRanges")
        self.item?.removeObserver(self, forKeyPath: "playbackBufferEmpty")
        self.item?.removeObserver(self, forKeyPath: "playbackLikelyToKeepUp")
        self.item?.removeObserver(self, forKeyPath: "rate")
        
        self.player?.removeTimeObserver(self.playbackTimerObserver)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: self.player?.currentItem)
        NotificationCenter.default.removeObserver(self, name: UIDevice.orientationDidChangeNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIApplication.willResignActiveNotification, object: nil)
        
        self.delegate?.canAutororate(canrorate: false)
        
        if self.player != nil {
            self.pause()
            self.anAsset = nil
            self.controlView.value = 0
            self.controlView.currentTime = "00:00"
            self.controlView.totalTime = "00:00"
            self.player = nil
            self.activityIndeView = nil
            self.removeFromSuperview()
        }
    }
    
    //MARK: 通知
    private func addNotificationCenter() {
        NotificationCenter.default.addObserver(self, selector: #selector(self.playerItemDidPlayToEndTimeNotification(notif:)), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: self.player?.currentItem)
        NotificationCenter.default.addObserver(self, selector: #selector(self.deviceOrientationDidChange(notif:)), name: UIDevice.orientationDidChangeNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.willResignActive(notif:)), name: UIApplication.willResignActiveNotification, object: nil)
    }
    
    @objc private  func playerItemDidPlayToEndTimeNotification(notif: NSNotification) {
        self.item?.seek(to: CMTime.zero)
        self.setSubViewIsHidden(hide: false)
        count = 0
        self.pause()
        self.pauseOrPlayView.btnImage.isSelected = false
    }
    
    @objc private  func deviceOrientationDidChange(notif: NSNotification) {
        if self.item != nil {
            if self.isShow {
                let interfaceOrientation = UIApplication.shared.statusBarOrientation
                switch interfaceOrientation {
                case .landscapeLeft:
                    
                    if isFullScreen == false {
                        isFullScreen = true
                        self.controlView.updateConstraintsIfNeeded()
                        //删除UIView animate可以去除横竖屏切换过渡动画
                        UIView.animate(withDuration: kTransitionTime, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0, options: .transitionCurlUp, animations: {
                            UIApplication.shared.keyWindow?.addSubview(self)
                            self.snp.makeConstraints({ (maker) in
                                maker.top.bottom.equalTo(UIApplication.shared.keyWindow!)
                                maker.left.equalTo(UIApplication.shared.keyWindow!).inset(0)
                                maker.right.equalTo(UIApplication.shared.keyWindow!).inset(0)
                            })
                            self.layoutIfNeeded()
                        }, completion: { (finished) in
                            self.delegate?.enterFullScreen()
                        })
                    }
                case .landscapeRight:
                    if isFullScreen == false {
                        isFullScreen = true
                        self.controlView.updateConstraintsIfNeeded()
                        //删除UIView animate可以去除横竖屏切换过渡动画
                        UIView.animate(withDuration: kTransitionTime, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0, options: .transitionCurlUp, animations: {
                            UIApplication.shared.keyWindow?.addSubview(self)
                            self.snp.makeConstraints({ (maker) in
                                maker.top.bottom.equalTo(UIApplication.shared.keyWindow!)
                                maker.left.equalTo(UIApplication.shared.keyWindow!).inset(0)
                                maker.right.equalTo(UIApplication.shared.keyWindow!).inset(0)
                            })
                            self.layoutIfNeeded()
                        }, completion: { (finished) in
                            self.delegate?.enterFullScreen()
                        })
                    }
                    
                    
                    //横屏另一种方案
                    //            if let vc = self.pushFullScreenVC() {
                    //                self.isFullScreen = true
                    //                self.fullScreenVC = vc
                    //                self.player?.pause()
                    //                self.fullScreenPlayer?.seekToTime(time: (self.item?.currentTime())!)
                    //                let second = (self.anAsset?.duration.value)! / CMTimeValue((self.anAsset?.duration.timescale)!)
                    //                self.fullScreenPlayer?.controlView.minValue = 0
                    //                self.fullScreenPlayer?.controlView.maxValue = CGFloat(second)
                    ////                self.fullScreenPlayer?.controlView.value = CGFloat((self.item?.currentTime().value)! / CMTimeValue((self.item?.currentTime().timescale)!))
                    //                self.getCurrentVC().present(self.fullScreenVC!, animated: false, completion: nil)
                    //            }
                    
                case .portraitUpsideDown:
                    break
                case .portrait:
                    if isFullScreen == true {
                        isFullScreen = false
                        if parentView == nil { return }
                        removeFromSuperview()
                        parentView!.addSubview(self)
                        let frame = parentView!.convert(viewFrame, to: UIApplication.shared.keyWindow)
                        //删除UIView animate可以去除横竖屏切换过渡动画
                        UIView.animate(withDuration: kTransitionTime, delay: 0, options: .curveLinear, animations: {
                            self.snp.remakeConstraints({ (make) in
                                make.centerX.equalTo(self.viewFrame.midX)
                                make.centerY.equalTo(self.viewFrame.midY)
                                make.width.equalTo(frame.width)
                                make.height.equalTo(frame.height)
                            })
                            self.layoutIfNeeded()
                        }, completion: { (finished) in
                            self.delegate?.quitFullScreen()
                        })
                    }
                    
                    
                    
                    //            if self.fullScreenVC != nil {
                    //                if self.fullScreenPlayer?.isPlaying == true {
                    //                    self.player?.play()
                    //                    self.controlView.setPlayButton(play: true)
                    //                    self.pauseOrPlayView.setupPlay(isPlay: true)
                    //                } else {
                    //                    self.player?.pause()
                    //                    self.controlView.setPlayButton(play: false)
                    //                    self.pauseOrPlayView.setupPlay(isPlay: false)
                    //                }
                    //
                    //                if (self.fullScreenPlayer!.item!.currentTime().value) / CMTimeValue(self.fullScreenPlayer!.item!.currentTime().timescale) > 0 {
                    //                    self.player?.seek(to: (self.fullScreenPlayer?.item?.currentTime())!)
                    //                }
                    //
                    //                self.fullScreenPlayer?.stop()
                    //                self.fullScreenPlayer = nil
                    //                self.fullScreenVC?.dismiss(animated: false, completion: nil)
                    //            }
                    
                default:
                    break
                }
                self.getCurrentVC().view.layoutIfNeeded()
            }
            }
    }
    
    @objc private  func willResignActive(notif: Notification) {
        if isPlaying {
            self.setSubViewIsHidden(hide: false)
            count = 0
            self.pause()
            self.pauseOrPlayView.btnImage.isSelected = false
        }
    }
    
    //MARK:Internal Helper
    //将数值转换成时间
    private func convertTime(second: CGFloat) -> String{
        let date = NSDate(timeIntervalSince1970: TimeInterval(second))
        let formatter = DateFormatter()
        if second / 3600 >= 1 {
            formatter.dateFormat = "HH:mm:ss"
        } else {
            formatter.dateFormat = "mm:ss"
        }
        let showtimeNew = formatter.string(from: date as Date)
        return showtimeNew
    }
    
    //获取当前屏幕显示的viewcontroller
    private func getCurrentVC() -> UIViewController{
        var result = UIViewController()
        let window = UIApplication.shared.keyWindow
        let frontView = window?.subviews[0]
        let nextResponder = frontView?.next
        if nextResponder is UIViewController {
            result = nextResponder as! UIViewController
        } else {
            result = (window?.rootViewController)!
        }
        return result
    }
    
    private func pushFullScreenVC() -> UIViewController? {
        if self.anAsset != nil {
            let vc = UIViewController()
            self.fullScreenPlayer = VideoPlayer(frame: CGRect(x: 0, y: 0, width: 100, height: 100), asset: self.anAsset!)
            vc.view.addSubview(self.fullScreenPlayer!)
            self.fullScreenPlayer?.snp.makeConstraints({ (maker) in
                maker.edges.equalTo(vc.view)
            })
            if self.isPlaying {
                self.fullScreenPlayer?.play()
                self.fullScreenPlayer?.pauseOrPlayView.setupPlay(isPlay: true)
            } else {
                self.fullScreenPlayer?.pause()
                self.fullScreenPlayer?.pauseOrPlayView.setupPlay(isPlay: false)
            }
            return vc
        } else {
            return nil
        }
    }
    
    //旋转方向
    func interfaceOrientation(orientation: UIInterfaceOrientation) {
        
    }
    
}

extension VideoPlayer: VideoPauseAndPlayViewDelegate, VideoControlViewDelegate{
    func getPointSliderLocation(controlView: VideoControlView, value: CGFloat) {
        if self.item != nil {
            count = 0
            let pointTime = CMTime(value: CMTimeValue(value) * CMTimeValue((self.item?.currentTime().timescale)!), timescale: (self.item?.currentTime().timescale)!)
            self.item?.seek(to: pointTime, toleranceBefore: CMTime.zero, toleranceAfter: CMTime.zero)
        }
    }
    
    func dragPositionWithSlider(controlView: VideoControlView, slider: UISlider) {
        if self.item != nil {
            count = 0
            let pointTime = CMTime(value: CMTimeValue(controlView.value) * CMTimeValue((self.item?.currentTime().timescale)!), timescale: (self.item?.currentTime().timescale)!)
            self.item?.seek(to: pointTime, toleranceBefore: CMTime.zero, toleranceAfter: CMTime.zero)
        }
    }
    
    func getLarge(controlView: VideoControlView, button: UIButton) {
        if self.item != nil {
            
            let statusBarOrientation = UIApplication.shared.statusBarOrientation
            if statusBarOrientation == .portrait{
                self.setupSuperViewFrame()
                UIDevice.current.setValue(UIInterfaceOrientation.landscapeRight.rawValue, forKey: "orientation")
            } else if statusBarOrientation == .landscapeLeft || statusBarOrientation == .landscapeRight {
                UIDevice.current.setValue(UIInterfaceOrientation.portrait.rawValue, forKey: "orientation")
            }
        }
        
        //        UIApplication.shared.statusBarOrientation = .landscapeRight
        //        UIApplication.shared.setStatusBarHidden(false, with: .fade)
    }
    
    func pauseOrPlayView(view: VideoPauseAndPlayView) {
        count = 0
        if isLoad {
            if !isPlaying {
                btnState = true
                self.play()
            } else {
                btnState = false
                self.pause()
            }
        } else {
            btnState = true
            self.pauseOrPlayView.setupPlay(isPlay: true)
            self.activityIndeView?.startAnimating()
            self.assetWithURL(url: url)
        }
    }
}

extension VideoPlayer: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if touch.view is VideoControlView {
            return false
        }
        return true
    }
}
