//
//  SocketIOManager.swift
//  SocketChat
//
//  Created by Alex Manukyan on 2/16/17.
//  Copyright © 2017 AppCoda. All rights reserved.
//

import UIKit

class SocketIOManager: NSObject {
    static let sharedInstance = SocketIOManager()
    var socket: SocketIOClient = SocketIOClient(socketURL: NSURL(string: "http://10.18.205.238:3000")!, config:nil)
    
    override init() {
        super.init()
    }
}

extension SocketIOManager{
    
    func establishConnection() {
        socket.connect()
    }
    
    
    func closeConnection() {
        socket.disconnect()
    }
    
     func sendSignalingMessage(message:[String:Any]){
        //print("SENDING: signalingMessage")
        socket.emit("signalingMessage", message)
    }
    
    func getSignalingMessage(completionHandler: @escaping (_ messageInfo: [String: Any]) -> Void) {
        socket.on("signalingMessage") { (dataArray, ack) -> Void in
            var message = [String: Any]()
            message["message"] = dataArray[0] as Any?
            completionHandler(message)
        }
    }
    
    func connectToServerWithNickname(nickname: String, completionHandler: @escaping (_ userList: [[String: AnyObject]]?) -> Void) {
        socket.emit("connectUser", nickname)
        
        socket.on("userList") { ( dataArray, ack) -> Void in
            completionHandler(dataArray[0] as? [[String: AnyObject]])
        }
        
        listenForOtherMessages()
    }
    
    func exitChatWithNickname(nickname: String, completionHandler: () -> Void) {
        socket.emit("exitUser", nickname)
        completionHandler()
    }
    
    func sendMessage(message: String, withNickname nickname: String) {
        socket.emit("chatMessage", nickname, message)
    }
    
    
    func getChatMessage(completionHandler: @escaping (_ messageInfo: [String: AnyObject]) -> Void) {
        socket.on("newChatMessage") { (dataArray, socketAck) -> Void in
            var messageDictionary = [String: AnyObject]()
            messageDictionary["nickname"] = dataArray[0] as AnyObject?
            messageDictionary["message"] = dataArray[1] as AnyObject?
            messageDictionary["date"] = dataArray[2] as AnyObject?
            
            completionHandler(messageDictionary)
        }
    }
    
    
    private func listenForOtherMessages() {
        socket.on("userConnectUpdate") { (dataArray, socketAck) -> Void in
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "userWasConnectedNotification"), object: dataArray[0] as! [String: AnyObject])
        }
        
        socket.on("userExitUpdate") { (dataArray, socketAck) -> Void in
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "userWasDisconnectedNotification"), object: dataArray[0] as! String)
        }
        
        socket.on("userTypingUpdate") { (dataArray, socketAck) -> Void in
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "userTypingNotification"), object: dataArray[0] as? [String: AnyObject])
        }
    }
    
    func sendStartTypingMessage(nickname: String) {
        socket.emit("startType", nickname)
    }
    
    func sendStopTypingMessage(nickname: String) {
        socket.emit("stopType", nickname)
    }
    
}

extension SocketIOManager{

}
