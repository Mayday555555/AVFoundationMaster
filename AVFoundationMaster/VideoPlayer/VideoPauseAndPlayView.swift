//
//  VideoPauseAndPlayView.swift
//
//  Created by 陈铉泽 on 2019/3/20.
//

import UIKit

@objc protocol VideoPauseAndPlayViewDelegate {
    func pauseOrPlayView(view: VideoPauseAndPlayView)
}

class VideoPauseAndPlayView: UIView {

    public var btnImage = UIButton()
    public weak var delegate: VideoPauseAndPlayViewDelegate? = nil
    var isPlay: Bool = false
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        btnImage = UIButton(type: UIButton.ButtonType.custom)
        btnImage.setImage(UIImage(named: "img_play"), for: .normal)
        btnImage.showsTouchWhenHighlighted = true
        btnImage.addTarget(self, action: #selector(self.handleBtnImageTapAction(btn:)), for: .touchUpInside)
        self.addSubview(self.btnImage)
        btnImage.snp.makeConstraints { (maker) in
            maker.centerY.equalToSuperview()
            maker.centerX.equalToSuperview()
            maker.height.equalTo(36)
            maker.width.equalTo(36)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func draw(_ rect: CGRect) {
        
    }
    
    @objc private func handleBtnImageTapAction(btn: UIButton) {
        self.delegate?.pauseOrPlayView(view: self)
    }
    
    public func setupPlay(isPlay: Bool) {
        self.isPlay = isPlay
        if self.isPlay {
            btnImage.setImage(UIImage(named: "img_suspend"), for: .normal)
        } else {
            btnImage.setImage(UIImage(named: "img_play"), for: .normal)
        }
    }
}
