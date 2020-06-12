//
//  ViewController.swift
//  What Would Micah Say
//
//  Created by asc on 6/11/20.
//  Copyright © 2020 Aaronland. All rights reserved.
//

import UIKit
import OAuthSwift
import AVFoundation

class ViewController: UIViewController {
    
    var oauth2: OAuthSwift?
    var credentials: OAuthSwiftCredential?
    
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
        
        getAccessToken(completion: WWMS)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.wwms_text.text = self.default_text
        self.wwms_asking.isHidden = true
    }
    
    private func WWMS(credentials: OAuthSwiftCredential){
        
        let api = CooperHewittAPI(access_token: credentials.oauthToken)
        let method = "cooperhewitt.labs.whatWouldMicahSay"
        let params = [String:String]()
        
        api.ExecuteMethod(method: method, params: params, completion: doWWMS)
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
    
    private func isExpired(credentials: OAuthSwiftCredential) -> Bool {
        
        var is_expired = credentials.isTokenExpired()
        
        if is_expired {
                        
            let dt = credentials.oauthTokenExpiresAt!
            
            // Cooper Hewitt
            
            if dt.timeIntervalSince1970 < 1.0 {
                is_expired = false
            }
        }
        
        return is_expired
    }
    
    private func getAccessToken(completion: @escaping (OAuthSwiftCredential) -> ()){
        print("AUTHORIZE")
        
        let keychain_label = "wwms://collection.cooperhewitt.org/access_token"
        
        if let creds = self.credentials {
                        
            if !isExpired(credentials: creds) {
                print("HAVE EXISTING TOKEN")
                completion(creds)
                return
            }
        }
        
        if let data = KeychainWrapper.standard.data(forKey: keychain_label) {
            
            print("GOT DATA", data)
            let decoder = JSONDecoder()
            var creds: OAuthSwiftCredential
            
            do {
                creds = try decoder.decode(OAuthSwiftCredential.self, from: data)
            } catch(let error) {
                print("SAD DECODE", error)
                return
            }
            
            if !isExpired(credentials: creds) {
                print("HAVE EXISTING TOKEN")
                completion(creds)
                return
            }
        }
        
        func getStore(credentials: OAuthSwiftCredential) {
            
            let encoder = JSONEncoder()
            
            do {
                let data = try encoder.encode(credentials)
                print("SAVE DATA", data)
                KeychainWrapper.standard.set(data, forKey: keychain_label)
            } catch (let error) {
                    print("SAD ENCODING", error)
            }
            
            self.credentials = credentials
            completion(credentials)
        }
        
        self.getNewAccessToken(completion: getStore)
    }
    
    private func getNewAccessToken(completion: @escaping (OAuthSwiftCredential) -> ()){
        
        print("GET NEW ACCESS TOKEN")
        
        let oauth2_auth_url = Bundle.main.object(forInfoDictionaryKey: "OAuth2AuthURL") as? String
        let oauth2_token_url = Bundle.main.object(forInfoDictionaryKey: "OAuth2TokenURL") as? String
        let oauth2_client_id = Bundle.main.object(forInfoDictionaryKey: "OAuth2ClientID") as? String
        let oauth2_client_secret = Bundle.main.object(forInfoDictionaryKey: "OAuth2ClientSecret") as? String
        let oauth2_scope = Bundle.main.object(forInfoDictionaryKey: "OAuth2Scope") as? String
        
        if oauth2_auth_url == nil || oauth2_auth_url == "" {
            //invalidConfigError(property: "OAuth2AuthURL")
            print("SAD AUTH URL")
            return
        }
        
        if oauth2_token_url == nil || oauth2_token_url == "" {
            //invalidConfigError(property: "OAuth2TokenURL")
            print("SAD TOKEN URL")
            return
        }
        
        if oauth2_client_id == nil || oauth2_client_id == "" {
            //invalidConfigError(property: "OAuth2ClientID")
            print("SAD CLIENT ID")
            return
        }
        
        if oauth2_client_secret == nil || oauth2_client_secret == "" {
            //invalidConfigError(property: "OAuth2ClientSecret")
            // print("SAD CLIENT SECRET")
            // Cooper Hewitt...
            // return
        }
        
        if oauth2_scope == nil || oauth2_scope == "" {
            //invalidConfigError(property: "OAuth2AuthURL")
            print("SAD SCOPE")
            return
        }
        
        let oauth2_state = UUID().uuidString
        
        var response_type = "token"
        var allow_missing_state = false
        
        response_type = "code" // Cooper Hewitt...
        allow_missing_state = true  // Cooper Hewitt...
        
        let oauth2 = OAuth2Swift(
            consumerKey:    oauth2_client_id!,
            consumerSecret: oauth2_client_secret!,
            authorizeUrl:   oauth2_auth_url!,
            accessTokenUrl: oauth2_token_url!,
            responseType:   response_type
        )
        
        oauth2.allowMissingStateCheck = allow_missing_state
        
        // make sure we retain the oauth2 instance (I always forget this part...)
        self.oauth2 = oauth2
        
        oauth2.authorize(
            withCallbackURL: "wwms://oauth2",
            scope: oauth2_scope!,
            state:oauth2_state
        ) { result in
            // print("RESULT", result)
            switch result {
            case .success(let (credential, _, _)):
                self.credentials = credential
                completion(credential)
            case .failure(let error):
                // https://github.com/OAuthSwift/OAuthSwift/blob/master/Sources/OAuthSwiftError.swift
                // https://github.com/OAuthSwift/OAuthSwift/wiki/Interpreting-Error-Codes
                print("SAD CALLBACK", error, error.localizedDescription)
                return
            }
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
