//
//  ViewController.swift
//  NekoCamera
//
//  Created by 樋口陽介 on 2016/07/29.
//  Copyright © 2016年 樋口陽介. All rights reserved.
//

import UIKit
import CoreLocation
import MediaPlayer
import MobileCoreServices

class ViewController: UIViewController, CLLocationManagerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    var trackLocationManager : CLLocationManager!
    var beaconRegion : CLBeaconRegion!
    var videoController : MPMoviePlayerController!
    var picker : UIImagePickerController!
    
    @IBOutlet weak var textView: UITextView!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        // ロケーションマネージャを作成する
        self.trackLocationManager = CLLocationManager();
        
        // デリゲートを自身に設定
        self.trackLocationManager.delegate = self;
        
        // セキュリティ認証のステータスを取得
        let status = CLLocationManager.authorizationStatus()
        
        // まだ認証が得られていない場合は、認証ダイアログを表示
        if(status == CLAuthorizationStatus.NotDetermined) {
            
            self.trackLocationManager.requestAlwaysAuthorization();
        }
        
        // BeaconのUUIDを設定
        let uuid:NSUUID? = NSUUID(UUIDString: "00000000-80F8-1001-B000-001C4D849D41")
        
        //Beacon領域を作成
        self.beaconRegion = CLBeaconRegion(proximityUUID: uuid!, identifier: "MyBeacon")
    }

    
    //位置認証のステータスが変更された時に呼ばれる
    func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        
        // 認証のステータス
        var statusStr = "";
        print("CLAuthorizationStatus: \(statusStr)")
        
        // 認証のステータスをチェック
        switch (status) {
        case .NotDetermined:
            statusStr = "NotDetermined"
        case .Restricted:
            statusStr = "Restricted"
        case .Denied:
            statusStr = "Denied"
            self.textView.text   = "位置情報を許可していません"
        case .Authorized:
            statusStr = "Authorized"
            self.textView.text   = "位置情報認証OK"
        default:
            break;
        }
        
        print(" CLAuthorizationStatus: \(statusStr)")
        
        //観測を開始させる
        trackLocationManager.startMonitoringForRegion(self.beaconRegion)
        
    }
    
    //観測の開始に成功すると呼ばれる
    func locationManager(manager: CLLocationManager, didStartMonitoringForRegion region: CLRegion) {
        
        print("didStartMonitoringForRegion");
        
        //観測開始に成功したら、領域内にいるかどうかの判定をおこなう。→（didDetermineState）へ
        trackLocationManager.requestStateForRegion(self.beaconRegion);
    }
    
    //領域内にいるかどうかを判定する
    func locationManager(manager: CLLocationManager, didDetermineState state: CLRegionState, forRegion inRegion: CLRegion) {
        
        switch (state) {
            
        case .Inside: // すでに領域内にいる場合は（didEnterRegion）は呼ばれない
            
            trackLocationManager.startRangingBeaconsInRegion(beaconRegion);
            // →(didRangeBeacons)で測定をはじめる
            break;
            
        case .Outside:
            
            // 領域外→領域に入った場合はdidEnterRegionが呼ばれる
            break;
            
        case .Unknown:
            
            // 不明→領域に入った場合はdidEnterRegionが呼ばれる
            break;
        }
    }
    
    //領域に入った時
    func locationManager(manager: CLLocationManager, didEnterRegion region: CLRegion) {
        
        // →(didRangeBeacons)で測定をはじめる
        self.trackLocationManager.startRangingBeaconsInRegion(self.beaconRegion)
        self.textView.text = "didEnterRegion"
        
        sendLocalNotificationWithMessage("領域に入りました")
    
    }
    
    //領域から出た時
    func locationManager(manager: CLLocationManager, didExitRegion region: CLRegion) {
        
        //測定を停止する
        self.trackLocationManager.stopRangingBeaconsInRegion(self.beaconRegion);
        
        reset();
        
        sendLocalNotificationWithMessage("領域から出ました");
        
    }
    
    //観測失敗
    func locationManager(manager: CLLocationManager, monitoringDidFailForRegion region: CLRegion?, withError error: NSError) {
        
        print("monitoringDidFailForRegion \(error)");
        
    }
    
    //通信失敗
    func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
        
        print("didFailWithError \(error)");
        
    }
    
    //領域内にいるので測定をする
    func locationManager(manager: CLLocationManager, didRangeBeacons beacons: [CLBeacon], inRegion region: CLBeaconRegion) {
        //println(beacons)
        
        if(beacons.count == 0) { return }
        
        var exists = false;
        var text = "";
        for beacon in beacons{
            
            /*
             beaconから取得できるデータ
             proximityUUID   :   regionの識別子
             major           :   識別子１
             minor           :   識別子２
             proximity       :   相対距離
             accuracy        :   精度
             rssi            :   電波強度
             */
            if (beacon.proximity == CLProximity.Unknown) {
                reset();
                return;
            } else if (beacon.proximity == CLProximity.Immediate) {
                text += "Immediate\n";
                exists = true;
            } else if (beacon.proximity == CLProximity.Near) {
                text += "Near\n";
            } else if (beacon.proximity == CLProximity.Far) {
                text += "Far\n";
            }
            text += "領域内です\n";
            text += beacon.proximityUUID.UUIDString + "\n";
            text += "\(beacon.major)\n";
            text += "\(beacon.minor)\n";
            text += "\(beacon.accuracy)\n";
            text += "\(beacon.rssi)\n";
            text += "-----------------------\n";
        }
        if(exists){
            if(self.picker == nil){
                self.startCaptureVideo();
            }
        }
        else{
            self.stopCaptureVideo();
        }
        textView.text = text
    }
    
    func reset(){
        self.stopCaptureVideo();
        textView.text = "";
    }
    
    func startCaptureVideo(){
        if (UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.Camera)){
            self.picker = UIImagePickerController();
            self.picker.delegate = self;
            self.picker.allowsEditing = true;
            self.picker.sourceType = UIImagePickerControllerSourceType.Camera;
            self.picker.mediaTypes = [kUTTypeMovie as String];
            self.picker.showsCameraControls = false;
            
            self.presentViewController(picker, animated: true, completion: { self.picker.startVideoCapture() });
        }
    }
    
    @IBAction func captureVideo(sender: UIButton) {
        self.startCaptureVideo();
    }
    
    func stopCaptureVideo(){
        if((self.picker) != nil){
            self.picker.stopVideoCapture();
        }
    }
    
    func ISOStringFromDate(date: NSDate) -> String {
        let dateFormatter = NSDateFormatter()
        dateFormatter.locale = NSLocale(localeIdentifier: "en_US_POSIX")
        dateFormatter.timeZone = NSTimeZone(abbreviation: "GMT")
        dateFormatter.dateFormat = "yyyyMMdd'T'HHmmssSSS"
        
        return dateFormatter.stringFromDate(date)
    }

    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]){
        let url = info[UIImagePickerControllerMediaURL] as? NSURL;
        if (url != nil) {
            // 端末のカメラロールに保存する
            UISaveVideoAtPathToSavedPhotosAlbum(url!.path!, self, #selector(ViewController.video(_:didFinishSavingWithError:contextInfo:)), nil)
        }

        picker.dismissViewControllerAnimated(true, completion: nil);
        self.picker = nil;
        return;
            
        self.videoController = MPMoviePlayerController();
        
        self.videoController.contentURL = url;
        self.videoController.view.frame = CGRectMake (0, 0, self.view.frame.size.width, 460);
        self.view.addSubview(self.videoController.view);
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ViewController.videoPlayBackDidFinish(_:)), name: MPMoviePlayerPlaybackDidFinishNotification, object: self.videoController);

        self.videoController.play();
    }

    func video(videoPath: String, didFinishSavingWithError error: NSError!, contextInfo: UnsafeMutablePointer<Void>) {
        if (error != nil) {
            print("動画の保存に失敗しました。")
        } else {
            print("動画の保存に成功しました。")
        }
    }
   
    func imagePickerControllerDidCancel(picker: UIImagePickerController){
        picker.dismissViewControllerAnimated(true, completion: nil);
    }
    
    func videoPlayBackDidFinish(notification:NSNotification) {
        NSNotificationCenter.defaultCenter().removeObserver(self,name:MPMoviePlayerPlaybackDidFinishNotification,object:nil);
        
        // Stop the video player and remove it from view
        self.videoController.stop();
        self.videoController.view.removeFromSuperview();
        self.videoController = nil;
        return;
        
        // Display a message
        let alertController = UIAlertController(title: "Video Playback",message: "Just finished the video playback. The video is now removed.",preferredStyle:UIAlertControllerStyle.Alert);
        let okayAction = UIAlertAction(title: "OK",style:UIAlertActionStyle.Default,handler:nil);
        alertController.addAction(okayAction);
        self.presentViewController(alertController, animated:true, completion:nil);
    }

    //ローカル通知
    func sendLocalNotificationWithMessage(message: String!) {
        let notification:UILocalNotification = UILocalNotification();
        notification.alertBody = message;
        
        UIApplication.sharedApplication().scheduleLocalNotification(notification);
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

