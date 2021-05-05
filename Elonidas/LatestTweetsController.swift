//
//  LatestTweetsController.swift
//  Elonis
//
//  Created by Ondrej Winter on 15.03.2021.
//

import UIKit
import Foundation
import Firebase
import FirebaseUI
import GoogleSignIn

class LatestTweetsController: UITableViewController, FUIAuthDelegate {
    
    
    // MARK: Properties
    
    var dataController: DataController!
    fileprivate var _filteredTwitterUsernamesHandle: DatabaseHandle!
    fileprivate var _allTweetsHandle: DatabaseHandle!
    fileprivate var _allTweetsSecondLoad: DatabaseHandle!
    var user: User?
    fileprivate var _authHandle: AuthStateDidChangeListenerHandle!
    var filteredTwitterUsernames: [DataSnapshot]! = []
    var filteredUsernames: [String] = []
    var tweets: [DataSnapshot]! = []
    @IBOutlet weak var label: UILabel!
    let now = Date()
    @IBOutlet var tweetsTableView: UITableView!
    
    // MARK: Outlets
    @IBOutlet var tweetsTable: UITableView!

    // MARK: Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureAuth()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.scrollToBottomTweet()
        }
    }
    
    func configureAuth() {
        // create authUI and add providers
        let authUI = FUIAuth.defaultAuthUI()
        authUI?.delegate = self
        let providers: [FUIAuthProvider] = [
          FUIGoogleAuth(),
            FUIEmailAuth(),
        ]
        authUI?.providers = providers
        
        
        // add listener if there was a change in the auth state, check if user variable on the view controller is the same as userAuth, if not - rewrite it, if there was no userAuth, present AuthUIVC
        _authHandle = Auth.auth().addStateDidChangeListener({ (auth, userAuth) in
            self.tweets.removeAll(keepingCapacity: false)
            self.filteredTwitterUsernames.removeAll(keepingCapacity: false)
            self.tweetsTable.reloadData()
            
            if let userAuth = userAuth {
                if self.user != userAuth {
                    self.user = userAuth
                    myAuth.user = userAuth
                    self.signedInStatus(isSignedIn: true)
                }
            } else {
                self.signedInStatus(isSignedIn: false)
            }
        })
    }
    
    // hepler function for authorization
    
    func signedInStatus(isSignedIn: Bool) {
        if isSignedIn {
            tweetsTable.dataSource = self
            tweetsTable.delegate = self
            self.tweetsTable.rowHeight = UITableView.automaticDimension
            self.tweetsTable.estimatedRowHeight = 122.0
            configureDatabase()
            let date = Date()
            let format = DateFormatter()
            format.dateFormat = "yyyy-MM-dd HH:mm:ss"
            let timestamp = format.string(from: date)
            
        } else {
            let authUI = FUIAuth.defaultAuthUI()
            let authViewController = authUI!.authViewController()
            self.present(authViewController, animated: true, completion: nil)
        }
    }
    
    
    // deinitialize so that when you don't use the app it doesn't listen for changes
    deinit {
        if let uid = self.user?.uid {
            dataController.ref.child("users").child("\(uid)").child("filteredTwitterUsernames").removeObserver(withHandle: _filteredTwitterUsernamesHandle)
            dataController.ref.child("users").child("\(uid)").child("allTweets").queryOrdered(byChild: Constants.AllTweets.createdAt).removeObserver(withHandle: _allTweetsHandle)
            dataController.ref.child("users").child("\(uid)").child("allTweets").queryOrdered(byChild: Constants.AllTweets.createdAt).removeObserver(withHandle: _allTweetsSecondLoad)
        }
        Auth.auth().removeStateDidChangeListener(_authHandle)
    }
    
    func configureDatabase() {
        filteredTwitterUsernames = []
        if let uid = self.user?.uid {
            
            // listen for changes on child filteredTwitterUsernames on Firbase DB. Add them to the VC variable and also dataController so that we can share the variable across VCs
            _filteredTwitterUsernamesHandle = dataController.ref.child("users").child("\(uid)").child("filteredTwitterUsernames").observe(.childAdded) { (snapshot: DataSnapshot) in
                    self.filteredTwitterUsernames.append(snapshot)
                    self.dataController.filteredUsernames.append(snapshot)
            }
            
            // load all tweets from Firebase that were already downloaded and saved, wait a bit so that you make sure you can ask variable tweets if there is really no data to show alert
                loadTweetsFromFirebase(uid: uid) { (bool) in
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        if self.tweets == [] {
                            Alert.showAlert(viewController: self, title: "Alert", message: "There are no recent tweets that would meet your filters at the moment.", actionTitle: "OK", style: .default)
                        }
                    }

                }
        }
    }
    
    func scrollToBottomTweet() {
        if tweets.count == 0 { return }
        let bottomMessageIndex = IndexPath(row: tweetsTable.numberOfRows(inSection: 0) - 1, section: 0)
        tweetsTable.scrollToRow(at: bottomMessageIndex, at: .bottom, animated: true)
    }
    

    @IBAction func refreshButtonTapped(_ sender: Any) {
       loadFilteredTweetsFromTwitter()
    }
    @IBAction func refreshWithScroll(_ sender: Any) {
        loadFilteredTweetsFromTwitter()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        self.filteredTwitterUsernames = dataController.filteredUsernames
    }
    
    

    func loadFilteredTweetsFromTwitter() {
        if self.filteredTwitterUsernames == [] {
            DispatchQueue.main.async {
                Alert.showAlert(viewController: self, title: "Alert", message: "There are no filters. Add some under Filters tab.", actionTitle: "OK", style: .default)
            }
        } else {
            DispatchQueue.main.async {
                self.tweets = []
                Spinner.start()
                self.tweetsTable.reloadData()
            }
        if let uid = self.user?.uid {
            dataController.ref.child("users").child("\(uid)").child("allTweets").queryOrdered(byChild: Constants.AllTweets.createdAt).removeObserver(withHandle: _allTweetsHandle)

            // run a counter so that you know when last tweet was saved to Firebase, so that you can ask for ordered tweets from Firebase and they are already all there
            var usernamesCounter = 0
            var matchCounter = 0
            
            for usernameData in self.filteredTwitterUsernames {
                // save the data from each username into variables
                let usernameDictionary = usernameData.value as! [String:String]
                let twUserId = usernameDictionary[Constants.Filters.twUserId] ?? ""
                let twFilteredWord = usernameDictionary[Constants.Filters.filteredWord] ?? ""
                let twUsername = usernameDictionary[Constants.Filters.twUsername] ?? ""
                usernamesCounter += 1
                
                // get recent tweets from the user and loop over them
                // note: not every request receives data, Twitter probably limits each API to ask for a recent tweets of a particular user
                getRecentTweetsFromTwId(userId: twUserId) { (tweetsObject, error) in
                    if let error = error {
                        print("error was there when loading new tweets")
                        self.loadTweetsFromFirebase(uid: uid) { bool in
                            
                        }
                        DispatchQueue.main.async {
                            Spinner.stop()
                            self.refreshControl?.endRefreshing()
                        }

                    } else {
                        self.tweets = []
                        var tweetsCounter = 0
                        
                        for tweet in tweetsObject[0].data {
                            // save data for each tweet into variables
                                    let tweetId = tweet.id
                                    let string = tweet.text
                                    let stringResult = string.contains(twFilteredWord)
                                    
                                    tweetsCounter += 1

                                    
                                    // if tweet that is looped over contains filtered word, save the tweet into Firebase and add it to tweet Ids
                                    if stringResult {
                                        var data = [Constants.AllTweets.text: string]
                                        data[Constants.AllTweets.tweetId] = tweetId
                                        data[Constants.AllTweets.createdAt] = tweet.createdAt
                                        data[Constants.AllTweets.username] = twUsername
                                        self.dataController.ref.child("users").child("\(uid)").child("allTweets").child("\(tweetId)").setValue(data)
                                        let idsData = ["id" : tweetId]
                                        self.dataController.ref.child("users").child("\(uid)").child("tweetsIdsByUsernames").child("\(twUsername)").child("ids").child("\(tweetId)").setValue(idsData)
                                    }
                                    
                                    if tweetsCounter == tweetsObject[0].data.count {
                                        matchCounter += 1
                                        
                                        // using delay to make sure all values are already set in Firebase db
                                        if matchCounter == self.filteredTwitterUsernames.count {
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                                self.tweets = []
                                                self.tweetsTable.reloadData()
                                                self._allTweetsHandle = self.dataController.ref.child("users").child("\(uid)").child("allTweets").queryOrdered(byChild: Constants.AllTweets.createdAt).observe(.childAdded, with: { [self] snapshot in
                                                    self.tweets.append(snapshot)
                                                    Spinner.stop()
                                                    self.refreshControl?.endRefreshing()
                                                    self.tweetsTable.insertRows(at: [IndexPath(row: self.tweets.count-1, section: 0)], with: .automatic)
                                                    self.scrollToBottomTweet()
                                                })
                                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                                    if self.tweets == [] {
                                                        Spinner.stop()
                                                        self.refreshControl?.endRefreshing()
                                                        Alert.showAlert(viewController: self, title: "Alert", message: "There are no recent tweets that would meet your filters at the moment.", actionTitle: "OK", style: .default)

                                                    }
                                                }
                                            }
                                        }
                                    }
                        }

                    }
                }
            }
        }
        }
    }
    
    
    func isLoadingTweets(isLoading:Bool) {
        if isLoading {
            Spinner.start()
            self.tweets = []
            tweetsTable.reloadData()
        } else {
            Spinner.stop()
            self.refreshControl?.endRefreshing()
        }
    }
    
    
    // helper function
    func getRecentTweetsFromTwId(userId: String, completion: @escaping ([GetTweetResponse],Error?) -> Void) {
        TwitterAPI.getRecentTweets(numberOfRecentTweets: 30, userId: userId) { (tweets, error) in
            if let error = error {
                completion([],error)
                return
            }
    
                completion(tweets, nil)
                        
        }
    }
    
    func transformISOStringToDate(isoString: String) -> Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"

        let iso = isoString
        let postedAt = dateFormatter.date(from: iso) // "change to format like: Jan 5, 2021, 5:50 PM"

        return postedAt
        
    }
    
    
    func loadTweetsFromFirebase(uid: String, completion: @escaping (Bool) -> Void){
        self.tweets = []
        // get tweets sorted by time
        _allTweetsHandle = dataController.ref.child("users").child("\(uid)").child("allTweets").queryOrdered(byChild: Constants.AllTweets.createdAt).observe(.childAdded, with: { [self] snapshot in
            self.tweets.append(snapshot)
            self.tweetsTable.insertRows(at: [IndexPath(row: self.tweets.count-1, section: 0)], with: .automatic)
        })
        completion(true)
    }
     
    
    
    @IBAction func signOutButtonTapped(_ sender: Any) {
        do {
            try Auth.auth().signOut()
        } catch {
            Alert.showAlert(viewController: self, title: "Alert", message: error.localizedDescription, actionTitle: "OK", style: .default)
        }
    }
    
    
    
    
    // MARK: Table View functions
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        self.tweetsTable.rowHeight = UITableView.automaticDimension
        self.tweetsTable.estimatedRowHeight = 122.0
        if tweets.count == 0 {
            var textview = UITextView(frame: CGRect(x: 20, y: 100, width: 100, height: 100))
            let window = UIWindow().addSubview(textview)
        }
        return tweets.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell! = tweetsTable.dequeueReusableCell(withIdentifier: "tweetCell", for: indexPath)
        let tweetSnapshot: DataSnapshot! = tweets[indexPath.row]
        let tweetData = tweetSnapshot.value as! [String:String]
        let text = tweetData[Constants.AllTweets.text] ?? "[text]"
        let twitterUsername = tweetData[Constants.AllTweets.username] ?? "username"
        let time = tweetData[Constants.AllTweets.createdAt] ?? "[time]"
        
        let createdAt = self.transformISOStringToDate(isoString: time)
        let timeAgo = createdAt?.timeAgoDisplay(now: now) ?? ""
       
        
        
        cell!.textLabel?.text = ("\(twitterUsername): ") + timeAgo + (" \(text)")
        return cell!
    }
    
    override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // If this is a NotesListViewController, we'll configure its `Notebook`
        if let vc = segue.destination as? TweetDetailViewController {
            if let indexPath = tweetsTable.indexPathForSelectedRow {
                vc.selectedTweet = tweets[indexPath.row]
            }
        }
    }
    
    //var secondTab = tabBarController?.viewControllers?[1] as AddFilterController
    //secondTab.dataController = 
    

}



extension Date {

        
    func timeAgoDisplay(now: Date) -> String {
        
        let postedAt = self
        let currentDate = Date()
        let diffComponents = Calendar.current.dateComponents([.day,.hour,.minute], from: postedAt, to: now)
        var days = diffComponents.day ?? 0
        var hours = diffComponents.hour ?? 0
        var minutes = diffComponents.minute ?? 0
        
        if days >= 1 {
            return "\(days) days ago"
        } else if hours >= 1 {
            return "\(hours) hours ago"
        } else if minutes >= 1 {
            return "\(minutes) minutes ago"
        } else if minutes < 1 {
            return "less than 1 minute ago"
        }
        
        return ""
    }

    
}



