//
//  ViewController.swift
//  AVFoundationMaster
//
//  Created by xuanze on 2019/8/19.
//  Copyright © 2019 xuanze. All rights reserved.
//

import UIKit
import AVFoundation
class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }

    /// 文字转语音
    @IBAction func AVSpeechSynthesizerTest(_ sender: Any) {
        let synthesizer = AVSpeechSynthesizer()
        let voice = AVSpeechSynthesisVoice(language: "zh-CN")
        let utterance = AVSpeechUtterance(string: "哈哈哈哈哈哈哈")
        utterance.rate = 1//播放速率
        utterance.voice = voice
//        utterance.pitchMultiplier = 0.8// 可在播放待定语句时候改变声调
        utterance.postUtteranceDelay = 0.1// 语音合成器在播放下一条语句的时候有短暂的停顿  这个属性指定停顿的时间
        synthesizer.speak(utterance)
        
        print("目前支持的语音列表:\(AVSpeechSynthesisVoice.speechVoices())")
    }
    
    @IBAction func toAVAudioPlayerVC(_ sender: Any) {
        let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "AVAudioPlayerViewController")
        self.present(vc, animated: true, completion: nil)
    }
    
    @IBAction func toAVAudioRecorder(_ sender: Any) {
        let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "AVAudioRecorderController")
        self.present(vc, animated: true, completion: nil)
    }
    
    @IBAction func playVideo(_ sender: Any) {
        let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "VideoPlayViewController") as? VideoPlayViewController
        vc?.movieURL = URL(string: "http://pic.ibaotu.com/00/34/48/06n888piCANy.mp4")
        self.present(vc!, animated: true, completion: nil)
        
    }
    
    @IBAction func CMTimeStudy(_ sender: Any) {
        let time1 = CMTimeMake(value: 1, timescale: 5)
        let time2 = CMTime.zero
        let time3 = CMTimeMake(value: 1, timescale: 44100)
        let time4 = CMTimeMake(value: 1, timescale: 10)
        CMTimeShow(time1)
        CMTimeShow(time2)
        CMTimeShow(time3)
        
        let timeA = CMTimeAdd(time1, time4)//加
        let timeS = CMTimeSubtract(time4, time1)//减
        let timeB = CMTimeMultiply(time1, multiplier: 2)//乘
        let timeb = CMTimeMultiplyByFloat64(time1, multiplier: 2)//乘 浮点型
        CMTimeShow(timeA)
        CMTimeShow(timeS)
        CMTimeShow(timeB)
        CMTimeShow(timeb)
        
        let compare = CMTimeCompare(time2, time2)//比较
        print(compare)
        
        let timeAB = CMTimeAbsoluteValue(timeS)//取绝对值
        CMTimeShow(timeAB)
    }
    
    
    @IBAction func recordVideo(_ sender: Any) {
        let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "VideoRecordViewController")
        self.present(vc, animated: true, completion: nil)
    }
    
    @IBAction func AVAsset(_ sender: Any) {
        if let path = Bundle.main.path(forResource: "薛之谦-像风一样.mp3", ofType: nil) {
            let url = URL(fileURLWithPath: path)
            let option = [AVURLAssetPreferPreciseDurationAndTimingKey: true]
            let asset = AVURLAsset(url: url, options: option)
            
            let keys = ["duration"]
            asset.loadValuesAsynchronously(forKeys: keys) {
                var error: NSError? = nil
                let status = asset.statusOfValue(forKey: "duration", error: &error)
                switch status {
                case .unknown:
                    print("未知")
                case .failed:
                    print("失败")
                case .loading:
                    print("正在加载")
                case .loaded:
                    print("载入成功")
                    print("duration: \(CMTimeGetSeconds(asset.duration))")
                default:
                    break
                }
                
            }
        }
        
        self.getAVMetadataItemMessage()
        
    }
    
    func getAVMetadataItemMessage() {
//        NSURL * url= [[NSBundle mainBundle]URLForResource:@"hubblecast" withExtension:@"m4v"];
//        //        NSURL * url = [NSURL URLWithString:YOUTUBE_URL];
//        AVAsset * asset = [AVAsset assetWithURL:url];
//        NSArray * keys  = @[@"availableMetadataFormats"];
//        NSMutableArray * metaArray =[NSMutableArray array];
//
//        // commonMetadata
//        NSArray * commonMetaArray = [asset commonMetadata];
//        NSLog(@"commonMetaArray = %@",commonMetaArray);
        let url = Bundle.main.url(forResource: "薛之谦-像风一样", withExtension: "mp3")
        let asset = AVURLAsset(url: url!)
        
        let commonMetaArray = asset.commonMetadata//从Common键空间获取元数据、这个属性会返回一个包括所有可用元数据的数组
        print(commonMetaArray)
        
        let keys = ["availableMetadataFormats"]
        
        var arrItem = [AVMetadataItem]()
        asset.loadValuesAsynchronously(forKeys: keys) {
            let formats = asset.availableMetadataFormats
            for dataFormat in formats {
                let items = asset.metadata(forFormat: dataFormat)
                print(items)
                arrItem.append(contentsOf: items)
            }
            
            for item in arrItem {
                print("\(item.key) \(item.value)\n")
            }
        }
        
        let array = asset.availableMediaCharacteristicsWithMediaSelectionOptions
        for string in array {
            if let group = asset.mediaSelectionGroup(forMediaCharacteristic: string) {
                for option in group.options {
                    print("option: \(option.displayName)")
                }
            }
        }
    }
    @IBAction func writer(_ sender: Any) {
        let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "VideoWriteViewController")
        self.present(vc, animated: true, completion: nil)
    }
    @IBAction func composition(_ sender: Any) {
        
        let vc = CompositionViewController()
        self.present(vc, animated: true) {
            
        }
    }
    
}

