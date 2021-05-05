//
//  TweetDetailViewController.swift
//  Elonidas
//
//  Created by Ondrej Winter on 03.04.2021.
//

import Foundation
import UIKit
import Firebase

class TweetDetailViewController: UIViewController {
    
    
    @IBOutlet weak var detailTweetTextView: UITextView!
    var selectedTweet: DataSnapshot!
    
    
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let tweetData = selectedTweet.value as! [String:String]
        let text = tweetData[Constants.AllTweets.text]

        detailTweetTextView.text = text
        adjustUITextViewHeight(arg: detailTweetTextView)
        
    }
    
    
    func adjustUITextViewHeight(arg : UITextView)
    {
        arg.translatesAutoresizingMaskIntoConstraints = true
        arg.sizeToFit()
        arg.isScrollEnabled = false
    }
    
    
}
