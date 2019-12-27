//
//  VideoControlView.swift
//
//  Created by 陈铉泽 on 2019/3/19.
//

import UIKit

@objc protocol VideoControlViewDelegate {
    func getPointSliderLocation(controlView: VideoControlView, value: CGFloat)
    func dragPositionWithSlider(controlView: VideoControlView, slider: UISlider)
    func getLarge(controlView: VideoControlView, button: UIButton)
}

var videoControlViewPadding = 8

class VideoControlView: UIView {
    // 屏幕宽
    private let Screen_Width = UIScreen.main.bounds.size.width
    
    // 屏幕高
    private let Screen_Height = UIScreen.main.bounds.size.height
    
    public weak var delegete: VideoControlViewDelegate? = nil
    private var tapGes = UITapGestureRecognizer()
    private var isPlay = false
    public var value:CGFloat {
        set {
            print("sliderValue:\(self):\(newValue)")
            print("max\(self.maxValue)")
            print("min\(self.minValue)")
            self.slider.value = Float(newValue)
        }
        get {
            return CGFloat(self.slider.value)
        }
    }
    public var minValue:CGFloat {
        set {
            self.slider.minimumValue = Float(newValue)
        }
        get {
            return CGFloat(self.slider.minimumValue)
        }
    }
    public var maxValue:CGFloat {
        set {
            self.slider.maximumValue = Float(newValue)
        }
        get {
            return CGFloat(self.slider.maximumValue)
        }
    }
    public var bufferValue: CGFloat {
        set {
            self.bufferSlier.value = Float(newValue)
        }
        get {
            return CGFloat(self.bufferSlier.value)
        }
    }
    
    public var currentTime: String {
        set {
           self.trackingTimeLabel.text = newValue
        }
        get {
            return self.trackingTimeLabel.text ?? ""
        }
    }
    
    public var totalTime: String {
        set {
            self.totalTimeLabel.text = newValue
        }
        get {
            return self.totalTimeLabel.text ?? ""
        }
    }

    private var slider: UISlider = {
        let slider = UISlider()
        slider.setThumbImage(UIImage(named: "knob"), for: .normal)
        slider.isContinuous = true
        slider.maximumTrackTintColor = UIColor.clear
        slider.minimumTrackTintColor = UIColor.white
        return slider
    }()
    
    private var largeButton: UIButton = {
        let button = UIButton(type: UIButton.ButtonType.custom)
        button.contentMode = .scaleToFill
        button.setImage(UIImage(named: "icon_video_fullscreen"), for: .normal)
        button.setImage(UIImage(named: "icon_video_fullscreen_pre"), for: .highlighted)
        return button
    }()
    
    //总时间
    private var totalTimeLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12)
        label.textColor = UIColor.white
        label.textAlignment = .right
        return label
    }()
    
    //当前播放时间
    private var trackingTimeLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12)
        label.textAlignment = .left
        label.textColor = UIColor.white
        return label
    }()
    
    private var bufferSlier: UISlider = {
        let slider = UISlider()
        slider.setThumbImage(UIImage(), for: .normal)
        slider.isContinuous = true
        if #available(iOS 10.0, *) {
            slider.minimumTrackTintColor = UIColor(displayP3Red: 92, green: 92, blue: 92, alpha: 1)
        } else {
            // Fallback on earlier versions
        }
        slider.minimumValue = 0
        slider.maximumValue = 1
        slider.isUserInteractionEnabled = false
        return slider
    }()
    
    private var viewMask: UIView = {
        let view = UIView()
        if #available(iOS 10.0, *) {
            view.backgroundColor = UIColor(displayP3Red: 23, green: 23, blue: 23, alpha: 1)
        } else {
            // Fallback on earlier versions
        }
        view.alpha = 0.4
        return view
    }()
    
    override func draw(_ rect: CGRect) {
        self.setupUI()
    }
    
    private func setupUI() {
        self.addSubview(viewMask)
        self.addSubview(self.bufferSlier)
        self.addSubview(self.slider)
        self.addSubview(self.largeButton)
        self.addSubview(self.totalTimeLabel)
        self.addSubview(self.trackingTimeLabel)
        self.addConstraintsForSubviews()
        self.largeButton.addTarget(self, action: #selector(self.handleLargeButton(btn:)), for: .touchUpInside)
        self.tapGes = UITapGestureRecognizer(target: self, action: #selector(self.handleTap(tap:)))
        self.slider.addGestureRecognizer(self.tapGes)
        self.slider.addTarget(self, action: #selector(self.hadleSliderPosition), for: .valueChanged)
        NotificationCenter.default.addObserver(self, selector: #selector(self.deviceOrientationDidChange), name: UIDevice.orientationDidChangeNotification, object: nil)
    }
    
    private func addConstraintsForSubviews() {
        self.viewMask.snp.makeConstraints { (maker) in
            maker.edges.equalToSuperview()
        }
        
        self.largeButton.snp.makeConstraints { (maker) in
            maker.right.equalToSuperview().offset(-16)
            maker.width.equalTo(25)
            maker.height.equalTo(40)
            maker.centerY.equalToSuperview()
        }
        
        self.trackingTimeLabel.snp.makeConstraints { (maker) in
            maker.left.equalToSuperview().offset(16)
            maker.width.equalTo(50)
            maker.height.equalTo(20)
            maker.centerY.equalToSuperview()
        }
        
        self.totalTimeLabel.snp.makeConstraints { (maker) in
            maker.centerY.equalToSuperview()
            maker.width.equalTo(50)
            maker.height.equalTo(20)
            maker.right.equalTo(self.largeButton.snp.left).offset(-16)
        }
        
        self.slider.snp.makeConstraints { (maker) in
            maker.left.equalTo(self.trackingTimeLabel.snp.right).offset(16)
            maker.right.equalTo(self.totalTimeLabel.snp.left).offset(-16)
            maker.centerY.equalToSuperview()
            if Screen_Width < Screen_Height {
//                Screen_Width - 16 - 50 - 16  - 16 - 50 - 16 - 25 - 16
                maker.width.equalTo(Screen_Width - 205)
            }
        }
        
        self.bufferSlier.snp.makeConstraints { (maker) in
            maker.edges.equalTo(self.slider)
        }
        
        
    }
    
    @objc private  func deviceOrientationDidChange() {
        self.addConstraintsForSubviews()
    }
    
    @objc private  func handleLargeButton(btn: UIButton) {
        self.delegete?.getLarge(controlView: self, button: largeButton)
    }
    
    @objc private  func hadleSliderPosition() {
        self.delegete?.dragPositionWithSlider(controlView: self, slider: slider)
    }
    
    @objc private  func handleTap(tap: UITapGestureRecognizer) {
        let point = tap.location(in: self.slider)
        let pointX = point.x
        let sliderWidth = self.slider.frame.size.width
        let currentValue = pointX / sliderWidth * CGFloat(self.slider.maximumValue)
        self.delegete?.getPointSliderLocation(controlView: self, value: currentValue)
    }
}

