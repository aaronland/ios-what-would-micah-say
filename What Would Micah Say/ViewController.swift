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

struct WWMSResponse: Codable {
    var micah: WWMS
    var stat: String
}

struct WWMS: Codable {
    var says: String
}

class ViewController: UIViewController {
    
    let app = UIApplication.shared.delegate as! AppDelegate
    
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
            self.showError(error: error)
        case .success(let credentials):
            
            let api = CooperHewittAPI(access_token: credentials.oauthToken)
            let method = "cooperhewitt.labs.whatWouldMicahSay"
            let params = [String:String]()
            
            api.ExecuteMethod(method: method, params: params, completion: doWWMS)
        }
    }
    
    private func doWWMS(rsp: Result<CooperHewittAPIResponse, Error>) {
        
        DispatchQueue.main.async {
            self.wwms_asking.stopAnimating()
            self.wwms_asking.isHidden = true
        }
        
        switch rsp {
        case .failure(let error):
            
            DispatchQueue.main.async {
                switch error {
                case is CooperHewittAPIError:
                    let api_error = error as! CooperHewittAPIError
                    self.showAlert(label: "Failed to read Micah", message: api_error.Message)
                default:
                    self.showAlert(label: "Failed to reach Micah", message: error.localizedDescription)
                }
                
            }
            return
            
            
        case .success(let api_rsp):
            
            let decoder = JSONDecoder()
            var wwms: WWMSResponse
            
            do {
                wwms = try decoder.decode(WWMSResponse.self, from: api_rsp.Data)
            } catch(let error) {
                self.showError(error: error)
                return
            }
            
            DispatchQueue.main.async {
                self.wwms_text.text = wwms.micah.says
                self.wwms_text.updateTextFont()
                
                let utterance = AVSpeechUtterance(string: wwms.micah.says)
                self.synthesizer.speak(utterance)
            }
        }
    }
    
    func showError(error: Error) {
        self.showAlert(label:"Error", message: error.localizedDescription)
    }
    
    func showAlert(label: String, message: String){
        
        self.app.logger.debug("Show alert \(label): \(message)")
        
        let alertController = UIAlertController(
            title: label,
            message: message,
            preferredStyle: .alert
        )
        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alertController, animated: true, completion: nil)
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
