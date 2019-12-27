//
//  CompositionViewController.swift
//  AVFoundationMaster
//
//  Created by xuanze on 2019/9/26.
//  Copyright © 2019 xuanze. All rights reserved.
//

import UIKit
import AVFoundation
class CompositionViewController: UIViewController {
    
    var exportSession: AVAssetExportSession!

    override func viewDidLoad() {
        super.viewDidLoad()

        
        self.firstSetup()
        
    }
    
    func firstSetup() {
        self.createAsset1()
    }
    
    func createAsset1() {
        let videoUrl : NSURL =  NSURL(fileURLWithPath: Bundle.main.path(forResource: "haha", ofType: "mov")!)
        let videoUrl1: NSURL = NSURL(fileURLWithPath: Bundle.main.path(forResource: "hubblecast", ofType: "m4v")!)
        let audioUrl : NSURL = NSURL(fileURLWithPath: Bundle.main.path(forResource: "薛之谦-像风一样", ofType: "mp3")!)
        
        let aVideoAsset : AVAsset = AVAsset(url: videoUrl as URL)
        let aVideoAsset1: AVAsset = AVAsset(url: videoUrl1 as URL)
        let aAudioAsset : AVAsset = AVAsset(url: audioUrl as URL)
        
        let mixComposition : AVMutableComposition = AVMutableComposition()


        //start merge
        let videoTrack = mixComposition.addMutableTrack(withMediaType: AVMediaType.video, preferredTrackID: kCMPersistentTrackID_Invalid)!
        let audioTrack = mixComposition.addMutableTrack(withMediaType: AVMediaType.audio, preferredTrackID: kCMPersistentTrackID_Invalid)!

        let aVideoAssetTrack : AVAssetTrack = aVideoAsset.tracks(withMediaType: AVMediaType.video)[0]
        let aVideoAssetTrack1 : AVAssetTrack = aVideoAsset1.tracks(withMediaType: AVMediaType.video)[0]
        let aAudioAssetTrack : AVAssetTrack = aAudioAsset.tracks(withMediaType: AVMediaType.audio)[0]


        do{
            try videoTrack.insertTimeRange(CMTimeRangeMake(start: CMTime.zero, duration: aVideoAssetTrack.timeRange.duration), of: aVideoAssetTrack, at: CMTime.zero)
            try videoTrack.insertTimeRange(CMTimeRangeMake(start: CMTime.zero, duration: aVideoAssetTrack1.timeRange.duration), of: aVideoAssetTrack1, at: aVideoAssetTrack.timeRange.duration)
            //In my case my audio file is longer then video file so i took videoAsset duration
            //instead of audioAsset duration

            try audioTrack.insertTimeRange(CMTimeRangeMake(start: CMTime.zero, duration: aVideoAssetTrack.timeRange.duration + aVideoAssetTrack1.timeRange.duration), of: aAudioAssetTrack, at: CMTime.zero)

            //Use this instead above line if your audiofile and video file's playing durations are same

            //            try mutableCompositionAudioTrack[0].insertTimeRange(CMTimeRangeMake(kCMTimeZero, aVideoAssetTrack.timeRange.duration), ofTrack: aAudioAssetTrack, atTime: kCMTimeZero)

        }catch{

        }

        //        playerItem = AVPlayerItem(asset: mixComposition)
        //        player = AVPlayer(playerItem: playerItem!)
        //
        //
        //        AVPlayerVC.player = player



        //find your video on this URl
        print(NSHomeDirectory() + "/Documents/newVideo.mp4")
        let savePathUrl : NSURL = NSURL(fileURLWithPath: NSHomeDirectory() + "/Documents/newVideo.mp4")

        let assetExport: AVAssetExportSession = AVAssetExportSession(asset: mixComposition, presetName: AVAssetExportPresetHighestQuality)!
        assetExport.outputFileType = AVFileType.mp4
        assetExport.outputURL = savePathUrl as URL
        assetExport.shouldOptimizeForNetworkUse = true

        assetExport.exportAsynchronously { () -> Void in
            switch assetExport.status {

            case AVAssetExportSessionStatus.completed:

                //Uncomment this if u want to store your video in asset

                //let assetsLib = ALAssetsLibrary()
                //assetsLib.writeVideoAtPathToSavedPhotosAlbum(savePathUrl, completionBlock: nil)

                print("success")
            case  AVAssetExportSessionStatus.failed:
                print("failed \(assetExport.error)")
            case AVAssetExportSessionStatus.cancelled:
                print("cancelled \(assetExport.error)")
            default:
                print("complete")
            }
        }

    }
    
   
    
    func createAsset() {
        let url = Bundle.main.url(forResource: "haha", withExtension: "mov")
        let videoAsset1 = AVURLAsset(url: url!, options: [AVURLAssetPreferPreciseDurationAndTimingKey: true])
        
        let url1 = Bundle.main.url(forResource: "haha", withExtension: "mov")
        let videoAsset2 = AVURLAsset(url: url1!, options: [AVURLAssetPreferPreciseDurationAndTimingKey: true])
        
        let url2 = Bundle.main.url(forResource: "薛之谦-像风一样", withExtension: "mp3")
        let audioAsset = AVURLAsset(url: url2!, options: [AVURLAssetPreferPreciseDurationAndTimingKey: true])
        
        let key = ["tracks","duration","commonMetadata"]
        videoAsset1.loadValuesAsynchronously(forKeys: key) {
            let staus1 = videoAsset1.statusOfValue(forKey: "tracks", error: nil)
            print(staus1.rawValue)
            let staus2 = videoAsset1.statusOfValue(forKey: "duration", error: nil)
            print(staus2.rawValue)
            let staus3 = videoAsset1.statusOfValue(forKey: "commonMetadata", error: nil)
            print(staus3.rawValue)
        }
        
        videoAsset2.loadValuesAsynchronously(forKeys: key) {
            let staus1 = videoAsset2.statusOfValue(forKey: "tracks", error: nil)
            print(staus1.rawValue)
            let staus2 = videoAsset2.statusOfValue(forKey: "duration", error: nil)
            print(staus2.rawValue)
            let staus3 = videoAsset2.statusOfValue(forKey: "commonMetadata", error: nil)
            print(staus3.rawValue)
        }
        
        audioAsset.loadValuesAsynchronously(forKeys: key) {
            let staus1 = audioAsset.statusOfValue(forKey: "tracks", error: nil)
            print(staus1.rawValue)
            let staus2 = audioAsset.statusOfValue(forKey: "duration", error: nil)
            print(staus2.rawValue)
            let staus3 = audioAsset.statusOfValue(forKey: "commonMetadata", error: nil)
            print(staus3.rawValue)
        }
        
        let composition = AVMutableComposition()
        let videoTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)
        let audioTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)
        
        
        var cursorTime = CMTime.zero
        let videoDuration = CMTime(value: 5, timescale: 1)
        let videoTimeRange = CMTimeRangeMake(start: CMTime.zero, duration: videoDuration)
        
        var assetTrack: AVAssetTrack!
        assetTrack = videoAsset1.tracks(withMediaType: .video).first
        
        //插入第一段
        do {
            try videoTrack?.insertTimeRange(videoTimeRange, of: assetTrack, at: cursorTime)
        } catch {
            print("insertVideo1 failed\(error.localizedDescription)")
        }
        
        //移动光标插入时间，让下一段内容在另一段内容最后插入。
        cursorTime = CMTimeAdd(cursorTime, videoDuration)

        assetTrack = videoAsset2.tracks(withMediaType: .video).first
        //插入第二段
        do {
            try videoTrack?.insertTimeRange(videoTimeRange, of: assetTrack, at: cursorTime)
        } catch {
            print("insertVideo2 failed\(error.localizedDescription)")
        }
        
        cursorTime = CMTime.zero
        
        let audioDuration = composition.duration
        let audioTimeRange = CMTimeRangeMake(start: CMTime.zero, duration: audioDuration)
        
        assetTrack = audioAsset.tracks(withMediaType: .audio).first
        do {
            try audioTrack?.insertTimeRange(audioTimeRange, of: audioTrack!, at: cursorTime)
        } catch {
            print("insertAudio failed\(error.localizedDescription)")
        }
        
//        let videoPlayer = VideoPlayer(frame: CGRect(x: 0, y: 200, width: UIScreen.main.bounds.size.width, height: 200), asset: composition)
//        self.view.addSubview(videoPlayer)
        
        let preset = AVAssetExportPresetLowQuality
        self.exportSession = AVAssetExportSession(asset: composition, presetName: preset)


//        let dataDirectory = NSTemporaryDirectory() + "Composition.mov"
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        var outputURL = paths[0]
        let manager = FileManager.default

        do {
           try manager.createDirectory(atPath: outputURL, withIntermediateDirectories: true, attributes: nil)
        } catch {
            print("createDirectory失败\(error.localizedDescription)")
        }

        outputURL += "/output.mov"
        print("outputURL:\(outputURL)")
        do {
           try manager.removeItem(atPath: outputURL)
        } catch {
            print("removeItem失败\(error.localizedDescription)")
        }
        self.exportSession.outputURL = URL(fileURLWithPath: outputURL)
        self.exportSession.outputFileType = .mov
        self.exportSession.shouldOptimizeForNetworkUse = true

        self.exportSession.exportAsynchronously {
            DispatchQueue.main.async {
                let exportStatus = self.exportSession!.status
                switch exportStatus {
                case .failed:
                    print("压缩失败")
                    print(self.exportSession.error.debugDescription)
                case .completed:
                    let data = NSData(contentsOfFile: outputURL)
                    print("视频压缩后的大小\(Float((data?.length)!) / 1024 / 1024)")
                default:
                    break
                }
            }
        }
        
    }
    
    
    

    

}
