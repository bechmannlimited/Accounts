//
//  asdfViewController.swift
//  Pods
//
//  Created by Alex Bechmann on 31/05/2015.
//
//

import UIKit

public enum Mobilizer {
    
    case None
    case Readability
}

public class WebViewController: UIViewController, UIWebViewDelegate {
    
    var url:String = ""
    var webView = UIWebView()
    var mobilizer = Mobilizer.None
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        webView = UIWebView(frame: CGRectZero)
        webView.delegate = self
        webView.setTranslatesAutoresizingMaskIntoConstraints(false)
        view.addSubview(webView)
        
        webView.addTopConstraint(toView: view, relation: .Equal, constant: 0)
        webView.addRightConstraint(toView: view, relation: .Equal, constant: 0)
        webView.addLeftConstraint(toView: view, relation: .Equal, constant: 0)
        webView.addBottomConstraint(toView: view, relation: .Equal, constant: 0)
        
        let requestURL = NSURL(string: urlWithMobilizer(mobilizer))
        let request = NSURLRequest(URL: requestURL!)
        webView.loadRequest(request)
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Back", style: .Plain, target: self, action: "back")
    }
    
    override public func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        UIApplication.sharedApplication().setStatusBarStyle(.Default, animated: true)
    }
    
    func back(){
        navigationController?.dismissViewControllerAnimated(true, completion: nil)
    }
    
    public func webViewDidFinishLoad(webView: UIWebView) {
        webView.hideLoader()
    }
    
    public func webViewDidStartLoad(webView: UIWebView) {
        webView.showLoader()
    }
    
    public func urlWithMobilizer(mobilizer: Mobilizer) -> String {
        
        var u = url
        
        switch mobilizer {
        case Mobilizer.Readability:
            u = "http://www.readability.com/m?url=" + url
            break
            
        default:
            break;
        }
        
        return u
    }
    
}