//
//  CommonVideoController.swift
//
//  Created by xuanze on 2019/6/18.
//

import UIKit
// 屏幕宽
fileprivate let Screen_Width = UIScreen.main.bounds.size.width
// 屏幕高
fileprivate let Screen_Height = UIScreen.main.bounds.size.height
// iphone X
fileprivate let IsiPhoneX = (Screen_Height == 812 || Screen_Height == 896) ? true : false

class CommonVideoController: UIViewController {

    open var url: String! {
        didSet {
            self.initVideoPlayer()
        }
    }
    private var videoPlayer: VideoPlayer!
    private var canAutorotate = false
    
    
    // tabbar高度
    private let TabBarHeight : CGFloat = IsiPhoneX ? 49 + 34 : 49
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let nav =  self.navigationController {
            nav.interactivePopGestureRecognizer?.isEnabled = false
            nav.setNavigationBarHidden(true, animated: false)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = true
        self.navigationController?.setNavigationBarHidden(false, animated: false)
    }
    
    deinit {
        self.videoPlayer.stop()
    }
    
    override var shouldAutorotate: Bool {
        return canAutorotate
    }
    
    // 屏幕方向
    override var supportedInterfaceOrientations : UIInterfaceOrientationMask {
        return [.portrait, .landscapeLeft, .landscapeRight]
    }
    
    private func setupUI() {
        self.view.backgroundColor = UIColor.black
    }
    
    private func initVideoPlayer() {
        self.videoPlayer = VideoPlayer(frame: CGRect(x: 0, y: 0, width: 20, height: 20), url: NSURL(string: url)!)
        self.videoPlayer.delegate = self
        self.videoPlayer.isShow = true
        self.view.addSubview(videoPlayer)
        videoPlayer.snp.makeConstraints { (maker) in
            maker.left.right.equalToSuperview()
            maker.top.equalTo(0)
            maker.bottom.equalToSuperview().offset(-(TabBarHeight - 49))
        }
        
        DispatchQueue.global().asyncAfter(deadline: DispatchTime.now() + 1) {
            DispatchQueue.main.async {
                self.videoPlayer.setupSuperViewFrame()
            }
        }
        self.videoPlayer.nowPlay()
    }

}

extension CommonVideoController: VideoPlayerDelegate {
    func enterFullScreen() {
        
    }
    
    func quitFullScreen() {
    }
    
    func canAutororate(canrorate: Bool) {
        self.canAutorotate = canrorate
        self.view.layoutIfNeeded()
    }
    
    func popController() {
        if let nav = self.navigationController {
            nav.popViewController(animated: true)
        } else {
            self.dismiss(animated: true) {
                
            }
        }
    }
}
