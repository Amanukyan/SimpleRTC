//
//  ViewController.swift
//  SimpleRTC
//
//  Created by Alex Manukyan on 2/18/17.
//  Copyright © 2017 Alex Manukyan. All rights reserved.
//


import UIKit
import AVFoundation


enum SignalingMessageType {
    case kSignalingMessageTypeCandidate
    case kSignalingMessageTypeOffer
    case kSignalingMessageTypeAnswer
    case kSignalingMessageTypeBye
}

class ViewController: UIViewController {
    
    
    var remoteView: RTCEAGLVideoView!
    var localView: RTCEAGLVideoView!
    var localVideoTrack: RTCVideoTrack!
    var remoteVideoTrack: RTCVideoTrack!
    
    var localStream: RTCMediaStream!
    
    var peerConnection: RTCPeerConnection!
    
    var iceServers: [Any]!
    var pcFactory: RTCPeerConnectionFactory!
    
    var id:String!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        id = UUID().uuidString
        
        prepareView()
        createPeerConnection()
        //initialize()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        SocketIOManager.sharedInstance.getSignalingMessage(completionHandler: {(messageInfo) in
            
            
            let message = messageInfo["message"] as! [String: Any]
            let senderID = message["senderID"] as! String
            if (senderID == self.id){
                //print("MESSAGE FROM SAME ID")
                return
            }
            //print("//******* RECEIVED MESSAGE **********//")
            //print(messageInfo)
            //print("//*******************************//")
            
            
            let type = message["type"] as! String
            if type == "candiate" {
                //ARDICECandidateMessage *message = [[ARDICECandidateMessage alloc] initWithCandidate:candidate];
                //[self sendSignalingMessage:message];
                
                //self.peerConnection.add(iceCandidate)
                
                let mid = message["candidateSDP_MID"] as! String
                let index = message["candidateSDP_LINE_INDEX"] as! Int
                let sdp = message["candidateSDP"] as! String
                let candidate = RTCICECandidate(mid: mid, index: index, sdp: sdp)
                self.peerConnection.add(candidate)
                
            } else if type == "sdp" {
                self.recievingSignalingMessage(sdp: message["description"] as! String)
            }
    
            
            
            
            
        })
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        //SocketIOManager.sharedInstance.sendStartTypingMessage(nickname: "ok")
        let pos = touches.first?.location(in: view)
        print(pos)
        //SocketIOManager.sharedInstance.sendPos(pos: pos)
        
    }
}

extension ViewController{
    func prepareView(){
        remoteView = RTCEAGLVideoView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height/2))
        remoteView.backgroundColor = UIColor.red
        view.addSubview(remoteView)
        
        localView = RTCEAGLVideoView(frame: CGRect(x: 0, y: view.frame.height/2, width: view.frame.width, height: view.frame.height/2))
        localView.backgroundColor = UIColor.green
        view.addSubview(localView)
        
        
        let button = UIButton(frame: CGRect(x: 0, y: 20, width: 100, height: 50))
        button.setTitle("Start", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = UIColor.black
        button.layer.cornerRadius = 5
        button.addGestureRecognizer(UIGestureRecognizer(target: self, action: #selector(initialize)))
        view.addSubview(button)
    }
}

extension ViewController{
    
    func createPeerConnection(){
        pcFactory = RTCPeerConnectionFactory()
        
        iceServers = [RTCICEServer(uri:URL(string:"stun:stun.l.google.com:19302"), username: "", password: "")] as [Any]
        
        peerConnection = pcFactory.peerConnection(withICEServers: iceServers, constraints: nil, delegate: self)
    }
    
    func initialize(){
        
        
        localStream = pcFactory.mediaStream(withLabel: "streamLABEL")
        
        let audioTrack = pcFactory.audioTrack(withID: "audioID")
        localStream!.addAudioTrack(audioTrack)
        
        
        let frontCameraVideoCapture = AVCaptureDevice.defaultDevice(withDeviceType: .builtInWideAngleCamera, mediaType: AVMediaTypeVideo, position: .front)
        
        
        let capturer = RTCVideoCapturer(deviceName: frontCameraVideoCapture?.localizedName)
        let videoSource = pcFactory.videoSource(with: capturer, constraints: nil)
        localVideoTrack = pcFactory.videoTrack(withID: "videoID", source: videoSource)
        localStream!.addVideoTrack(localVideoTrack)
        
        //renderer
        localVideoTrack?.add(self.localView)
        
        
        
        peerConnection!.add(localStream)
        
        
        let constaints = RTCMediaConstraints(mandatoryConstraints: [RTCPair(key: "OfferToReceiveAudio", value: "true"),
                                                                    RTCPair(key: "OfferToReceiveVideo", value: "true")],
                                             optionalConstraints: nil)
        peerConnection?.createOffer(with: self, constraints: constaints)
        
    }
}


extension ViewController{
    func sendSignalingMessage(message:[String:Any]){
        SocketIOManager.sharedInstance.sendSignalingMessage(message: message)
    }
    
    func recievingSignalingMessage(sdp:String){
        
        let remoteDesc = RTCSessionDescription(type: "offer", sdp: sdp)
        peerConnection.setRemoteDescriptionWith(self, sessionDescription: remoteDesc)
    }
}


extension ViewController: RTCEAGLVideoViewDelegate{
    
    func videoView(_ videoView: RTCEAGLVideoView!, didChangeVideoSize size: CGSize) {
        
    }
}

extension ViewController: RTCPeerConnectionDelegate{
    func peerConnection(_ peerConnection: RTCPeerConnection!, signalingStateChanged stateChanged: RTCSignalingState) {
        print("stateChanged:",stateChanged)
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection!, removedStream stream: RTCMediaStream!) {
        print("removedStream")
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection!, addedStream stream: RTCMediaStream!) {
        print("ADDED STREAM: \(stream.videoTracks.count) videos tracks")
        
        
        DispatchQueue.main.async {
            if stream.videoTracks.count > 0 {
                print("ok")
                let videoTrack = stream.videoTracks[0] as! RTCVideoTrack
                self.remoteVideoTrack = videoTrack
                self.remoteVideoTrack.add(self.remoteView)
            }
        }
        
        
    }
    
    func peerConnection(onRenegotiationNeeded peerConnection: RTCPeerConnection!) {
        print("onRenegotiationNeeded")
    }
    func peerConnection(_ peerConnection: RTCPeerConnection!, didOpen dataChannel: RTCDataChannel!) {
        print("didOpen dataChannel")
    }
    func peerConnection(_ peerConnection: RTCPeerConnection!, gotICECandidate candidate: RTCICECandidate!) {
        print("gotICECandidate")
        var message = [String: Any]()
        message["type"] = "candidate"
        message["senderID"] = id
        message["candidateSDP"] = candidate.sdp
        message["candidateSDP_MID"] = candidate.sdpMid
        message["candidateSDP_LINE_INDEX"] = candidate.sdpMLineIndex
        SocketIOManager.sharedInstance.sendSignalingMessage(message: message)
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection!, iceGatheringChanged newState: RTCICEGatheringState) {
        print("iceGatheringChanged: ",newState)
        
    }
    func peerConnection(_ peerConnection: RTCPeerConnection!, iceConnectionChanged newState: RTCICEConnectionState) {
        print("iceConnectionChanged: ", newState)
    }
    
}

extension ViewController: RTCSessionDescriptionDelegate{
    func peerConnection(_ peerConnection: RTCPeerConnection!, didCreateSessionDescription sdp: RTCSessionDescription!, error: Error!) {
        print("didCreateSessionDescription")
        if error != nil {
            print("error")
            return
        }
        
        /*
        if (peerConnection.signalingState == RTCSignalingHaveLocalOffer) {
            self.peerConnection.setLocalDescriptionWith(self, sessionDescription: sdp)
            print("_setLocalDescriptionWith")
        }
        if peerConnection.signalingState == RTCSignalingHaveRemoteOffer {
            self.peerConnection.setRemoteDescriptionWith(self, sessionDescription: sdp)
            print("_setRemoteDescriptionWith")
        }
        */
        var message = [String: Any]()
        message["description"] = sdp.description as Any?
        message["type"] = "sdp"
        message["senderID"] = id
        SocketIOManager.sharedInstance.sendSignalingMessage(message: message)
        
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection!, didSetSessionDescriptionWithError error: Error!) {
        print("didSetSessionDescriptionWithError")
        
        if (peerConnection.signalingState == RTCSignalingHaveLocalOffer) {
            // Send offer through the signaling channel of our application
            print("_______RTCSignalingHaveLocalOffer")
        }
        
        if peerConnection.signalingState == RTCSignalingHaveRemoteOffer {
            print("_______RTCSignalingHaveRemoteOffer")
            
            //self.peerConnection = peerConnection
            let constaints = RTCMediaConstraints(mandatoryConstraints: [RTCPair(key: "OfferToReceiveAudio", value: "true"),
                                                                        RTCPair(key: "OfferToReceiveVideo", value: "true")],
                                                 optionalConstraints: nil)
            peerConnection.createAnswer(with: self, constraints: constaints)
        }
        
    }
}

