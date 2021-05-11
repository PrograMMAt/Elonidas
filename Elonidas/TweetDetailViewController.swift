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
    var selectedTweet: TweetDictionary!
    
    
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let text = selectedTweet.text

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
