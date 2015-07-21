//
//  CompresJsonRequest.swift
//  CompresJSON
//
//  Created by Alex Bechmann on 09/05/2015.
//  Copyright (c) 2015 Alex Bechmann. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON

public class CompresJsonRequest: JsonRequest {
   
    var shouldEncrypt = CompresJSON.sharedInstance().settings.shouldEncrypt
    var shouldCompress = CompresJSON.sharedInstance().settings.shouldCompress
    var acceptEncoding = ""
    
    override public class func create< T : JsonRequest >(urlString:String, parameters:Dictionary<String, AnyObject>?, method:Alamofire.Method) -> T {
        
        return CompresJsonRequest(urlString: urlString, parameters: parameters, method: method) as! T
    }
    
//    public class func create(urlString:String, parameters:Dictionary<String, AnyObject>?, method:Alamofire.Method, shouldEncrypt:Bool, acceptEncoding: String) -> CompresJsonRequest {
//        
//        return CompresJsonRequest(urlString: urlString, parameters: parameters, method: method, shouldEncrypt: shouldEncrypt, acceptEncoding: acceptEncoding)
//    }
    
//    convenience init(urlString: String, parameters: Dictionary<String, AnyObject>?, method: Alamofire.Method, shouldEncrypt: Bool, acceptEncoding: String) {
//        self.init()
//        
//        self.urlString = urlString
//        self.parameters = parameters
//        self.method = method
//        self.shouldEncrypt = shouldEncrypt
//        self.acceptEncoding = acceptEncoding
//        
//        exec()
//    }
    
    internal override func exec() {
        
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
        
        if let params = self.parameters {
            
            if shouldEncrypt || shouldCompress{
                
                var err: NSError?
                var json: String = NSJSONSerialization.dataWithJSONObject(params, options: nil, error: &err)!.toString()
                
                json = CompresJSON.encryptAndCompressAsNecessary(json, shouldEncrypt: shouldEncrypt, shouldCompress: shouldCompress)
                
                self.parameters = Dictionary<String, AnyObject>()
                self.parameters!["data"] = json
            }
        }
        
        self.alamofireRequest = request(self.method, self.urlString, parameters: self.parameters, encoding: ParameterEncoding.URL)
            .response{ (request, response, data, error) in
                
                if let e = error {
                    
                    println(e.localizedDescription)
                    
                    var alert = self.alertControllerForError(e, completion: { (retry) -> () in
                        
                        if retry {
                            
                            self.cancel()
                            self.exec()
                        }
                    })
                    
                    self.failDownload(e, alert: alert)
                }
                    
                else{
                    let json = JSON(data: data! as! NSData)
                    
                    if self.shouldEncrypt || self.shouldCompress {
                        
                        let encryptedJson = json["data"].stringValue
                        let unencryptedJson = CompresJSON.decryptAndDecompressAsNecessary(encryptedJson, shouldEncrypt: self.shouldEncrypt, shouldCompress: self.shouldCompress)
                        
                        if let dataFromString = unencryptedJson.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false){
                            
                            let unpackedJson = JSON(data: dataFromString)
                            
                            self.succeedDownload(unpackedJson, httpUrlRequest: request, httpUrlResponse: response)
                        }
                        else {
                            
                            println("got nil - retrying")
                            self.cancel()
                            self.exec()
                        }
                    }
                    else {
                        
                        self.succeedDownload(json, httpUrlRequest: request, httpUrlResponse: response)
                    }
                }
                
                self.finishDownload()
                UIApplication.sharedApplication().networkActivityIndicatorVisible = false
        }
    }
    
}
