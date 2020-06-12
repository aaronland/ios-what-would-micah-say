//
//  ViewController.swift
//  What Would Micah Say
//
//  Created by asc on 6/11/20.
//  Copyright © 2020 Aaronland. All rights reserved.
//

import UIKit
import OAuth2Wrapper
import OAuthSwift
import AVFoundation

class ViewController: UIViewController {
    
    let oauth2_id = "mmws://collection.cooperhewitt.org/access_token"
    let oauth2_callback_url = "wwms://oauth2"
    
    var oauth2_wrapper: OAuth2Wrapper?

    let synthesizer = AVSpeechSynthesizer()
    
    let default_text = "Press the \"💬\" button to see what Micah thinks."
    
    @IBOutlet var wwms_asking: UIActivityIndicatorView!
    
    @IBOutlet var wwms_text: UITextView!
    
    @IBOutlet var wwms_button: UIButton!
    
    @IBAction func triggerWWMS() {
        
        self.synthesizer.stopSpeaking(at: .immediate)
        self.wwms_text.text = ""
        
        self.wwms_asking.startAnimating()
        self.wwms_asking.isHidden = false
        
        self.oauth2_wrapper!.GetAccessToken(completion: WWMS)
    }
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        self.wwms_text.text = self.default_text
        self.wwms_asking.isHidden = true
        
        let wrapper = OAuth2Wrapper(id: self.oauth2_id, callback_url: self.oauth2_callback_url)
        wrapper.response_type = "code"
        wrapper.allow_missing_state = true
        wrapper.require_client_secret = false
        wrapper.allow_null_expires = true
        
        // wrapper.logger.logLevel = .debug
        
        self.oauth2_wrapper = wrapper
    }
    
    private func WWMS(rsp: Result<OAuthSwiftCredential, Error>){
        
        switch rsp {
        case .failure(let error):
                print("SAD", error)
        case .success(let credentials):
        
        let api = CooperHewittAPI(access_token: credentials.oauthToken)
        let method = "cooperhewitt.labs.whatWouldMicahSay"
        let params = [String:String]()
        
        api.ExecuteMethod(method: method, params: params, completion: doWWMS)
        }
    }
    
    private func doWWMS(response: Result<Data, Error>) {
        
        DispatchQueue.main.async {
            self.wwms_asking.stopAnimating()
            self.wwms_asking.isHidden = true
        }
        
        var data: Data?
        
        switch response {
        case .failure(let error):
            print("SAD", error)
        case .success(let raw):
            data = raw
        }
        
        let decoder = JSONDecoder()
        var rsp: WWMSResponse
        
        do {
            rsp = try decoder.decode(WWMSResponse.self, from: data!)
        } catch(let error) {
            print("SAD JSON", error)
            return
        }
        
        DispatchQueue.main.async {
            
            self.wwms_text.text = rsp.micah.says
            self.wwms_text.updateTextFont()
            
            let utterance = AVSpeechUtterance(string: rsp.micah.says)
            self.synthesizer.speak(utterance)
        }
    }
  
}

extension UITextView {
    func updateTextFont() {
        if (self.text.isEmpty || self.bounds.size.equalTo(CGSize.zero)) {
            return;
        }
        
        let textViewSize = self.frame.size;
        let fixedWidth = textViewSize.width;
        let expectSize = self.sizeThatFits(CGSize(width: fixedWidth, height: CGFloat(MAXFLOAT)))
        
        
        var expectFont = self.font
        if (expectSize.height > textViewSize.height) {
            
            while (self.sizeThatFits(CGSize(width: fixedWidth, height: CGFloat(MAXFLOAT))).height > textViewSize.height) {
                expectFont = self.font!.withSize(self.font!.pointSize - 1)
                self.font = expectFont
            }
        }
        else {
            while (self.sizeThatFits(CGSize(width: fixedWidth, height: CGFloat(MAXFLOAT))).height < textViewSize.height) {
                expectFont = self.font
                self.font = self.font!.withSize(self.font!.pointSize + 1)
            }
            self.font = expectFont
        }
    }
}
