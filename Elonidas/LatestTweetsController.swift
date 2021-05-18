//
//  LatestTweetsController.swift
//  Elonis
//
//  Created by Ondrej Winter on 15.03.2021.
//

import Foundation
import UIKit
import Firebase
import FirebaseUI
import GoogleSignIn

class LatestTweetsController: UITableViewController, FUIAuthDelegate {
    
    
    // MARK: Properties
    
    var dataController: DataController!
    fileprivate var _filteredTwitterUsernamesHandle: DatabaseHandle!
    fileprivate var _allTweetsHandle: DatabaseHandle!
    var user: User?
    fileprivate var _authHandle: AuthStateDidChangeListenerHandle!
    var filteredTwitterUsernames: [DataSnapshot]! = []
    var tweets: [DataSnapshot]! = []
    let now = Date()
    var isContentRefreshed: Bool = false
    var tweetIds: [String] = []
    
    // MARK: Outlets
    @IBOutlet weak var label: UILabel!
    @IBOutlet var tweetsTableView: UITableView!
    @IBOutlet var tweetsTable: UITableView!

    // MARK: Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureAuth()
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
            
            loadTweetsFromFirebase(uid: uid)
            isLoadingTweets(isLoading: true)
        }
        // wait if listeners get some data if not show alert that there are no filters
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            if self.filteredTwitterUsernames == [] {
                Alert.showAlert(viewController: self, title: "Alert", message: "There are no filters. Add some under Filters tab.", actionTitle: "OK", style: .default)
                self.isLoadingTweets(isLoading: false)
            }
            self.isLoadingTweets(isLoading: false)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        tableView.reloadData()
        super.viewWillAppear(true)
        self.filteredTwitterUsernames = dataController.filteredUsernames
    }

    @IBAction func refreshButtonTapped(_ sender: Any) {
        isContentRefreshed = true
        loadFilteredTweetsFromTwitterOnRefresh()
        
    }
    @IBAction func refreshWithScroll(_ sender: Any) {
        isContentRefreshed = true
        loadFilteredTweetsFromTwitterOnRefresh()
    }


    func loadFilteredTweetsFromTwitterOnRefresh() {
        
        var twArray: [NewTweet] = []
        
        // show alert if there are no active filters
        if self.filteredTwitterUsernames == [] {
            DispatchQueue.main.async {
                Alert.showAlert(viewController: self, title: "Alert", message: "There are no filters. Add some under Filters tab.", actionTitle: "OK", style: .default)
            }
        } else {
            isLoadingTweets(isLoading: true)
        if let uid = self.user?.uid {
            
            for usernameData in self.filteredTwitterUsernames {
                // save the data from each username into variables
                let usernameDictionary = usernameData.value as! [String:String]
                let twUserId = usernameDictionary[Constants.Filters.twUserId] ?? ""
                var twFilteredWord = usernameDictionary[Constants.Filters.filteredWord] ?? ""
                let twUsername = usernameDictionary[Constants.Filters.twUsername] ?? ""
                
                // get recent tweets from the user, loop over them
                getRecentTweetsFromTwId(userId: twUserId) { (tweetsObject, error) in
                    if let error = error {
                        self.isLoadingTweets(isLoading: false)
                    } else {

                        for tweet in tweetsObject[0].data {
                            
                            let tweetId = tweet.id
                            
                            if !self.tweetIds.contains(tweetId) {
                                let string = tweet.text.lowercased()
                                twFilteredWord = twFilteredWord.lowercased()
                                let stringResult = string.contains(twFilteredWord)
                                
                                
                                // if tweet that is looped over contains filtered word, save the tweet into Firebase and add it to tweet Ids
                                if stringResult {
                                    let username = twUsername
                                    let createdAt = tweet.createdAt
                                    
                    
                                    if let tweetIdNumber = Int(tweetId) {
                                        // create a NewTweet that holds tweetId as number
                                        let tweetWithIdInt = NewTweet(username: username, tweetId: tweetIdNumber, text: string, createdAt: createdAt)
                                        twArray.append(tweetWithIdInt)
                                        
                                        // set up data for Firebase, where we hold tweetId as String and send it there, also append tweetId to tweetIds array
                                        var data = [Constants.AllTweets.text: tweet.text]
                                        data[Constants.AllTweets.tweetId] = tweet.id
                                        data[Constants.AllTweets.createdAt] = tweet.createdAt
                                        data[Constants.AllTweets.username] = twUsername
                                        self.dataController.ref.child("users").child("\(uid)").child("allTweets").child("\(tweet.id)").setValue(data)
                                        let idsData = ["id" : tweet.id]
                                        self.dataController.ref.child("users").child("\(uid)").child("tweetsIdsByUsernames").child("\(twUsername)").child("ids").child("\(tweet.id)").setValue(idsData)
                                        self.tweetIds.append(tweet.id)
                                    }
                                }
                            }
                        }
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            Spinner.stop()
                            self.refreshControl?.endRefreshing()
                        }
                    }
                }
            }
        }
        }
    }
    
    
    
    func isLoadingTweets(isLoading:Bool) {
        if isLoading {
            DispatchQueue.main.async {
                Spinner.start()
            }
        } else {
            DispatchQueue.main.async {
                Spinner.stop()
                self.refreshControl?.endRefreshing()
            }
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
    
    
    func loadTweetsFromFirebase(uid: String) -> () {
        
        // add handle
        _allTweetsHandle = dataController.ref.child("users").child("\(uid)").child("allTweets").queryOrdered(byChild: Constants.AllTweets.createdAt).observe(.childAdded, with: { [self] snapshot in
            
            // check if loading was invoked by refresh function (tap and scroll), or whether it was a first load, on first load tweets are already sorted based on when tweets were created
            if isContentRefreshed {
                let dict = snapshot.value as! [String:Any]
                
                if let username = dict[Constants.AllTweets.username] as? String,
                let stringTweetId = dict[Constants.AllTweets.tweetId] as? String,
                let text = dict[Constants.AllTweets.text] as? String,
                let createdAt = dict[Constants.AllTweets.createdAt] as? String {
                    let tweet = TweetDictionary(username: username, tweetId: stringTweetId, text: text, createdAt: createdAt)
                    dataController.tweetsArray.append(tweet)
                    let index = dataController.tweetsArray.firstIndex(where: { $0.tweetId == tweet.tweetId })
                    dataController.tweetsArray = dataController.tweetsArray.sorted(by: { $0.tweetId > $1.tweetId })
                    let bIndex = dataController.tweetsArray.firstIndex(where: { $0.tweetId == tweet.tweetId })
                    
                    self.tableView.performBatchUpdates({
                        self.tableView.insertRows(at: [IndexPath(row: bIndex!,section: 0)],with: .automatic)
                    }, completion: nil)
                }

                
            } else {
                let dict = snapshot.value as! [String:Any]
                
                if let username = dict[Constants.AllTweets.username] as? String,
                let stringTweetId = dict[Constants.AllTweets.tweetId] as? String,
                let text = dict[Constants.AllTweets.text] as? String,
                let createdAt = dict[Constants.AllTweets.createdAt] as? String {
                    let tweet = TweetDictionary(username: username, tweetId: stringTweetId, text: text, createdAt: createdAt)
                    self.dataController.tweetsArray.insert(tweet, at: 0)
                    self.tableView.performBatchUpdates({
                        self.tableView.insertRows(at: [IndexPath(row: 0,section: 0)],with: .automatic)
                    }, completion: nil)
                    self.tweetIds.append(stringTweetId)
                }
                isLoadingTweets(isLoading: false)
            }
        })
    }
    
     
    func transformISOStringToDate(isoString: String) -> Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"

        let iso = isoString
        let postedAt = dateFormatter.date(from: iso) // "change to format like: Jan 5, 2021, 5:50 PM"

        return postedAt
        
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
        return dataController.tweetsArray.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell! = tweetsTable.dequeueReusableCell(withIdentifier: "tweetCell", for: indexPath)
        let tweetData = dataController.tweetsArray[indexPath.row] as TweetDictionary
        let text = tweetData.text
        let twUsername = tweetData.username
        let time = tweetData.createdAt
        let createdAt = self.transformISOStringToDate(isoString: time)
        let timeAgo = createdAt?.timeAgoDisplay(now: now) ?? "createdAt"
        cell!.textLabel?.text = ("\(twUsername): ") + timeAgo + (" \(text)")
        
        return cell!
    }
    
    override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // If this is a NotesListViewController, we'll configure its `Notebook`
        if let vc = segue.destination as? TweetDetailViewController {
            if let indexPath = tweetsTable.indexPathForSelectedRow {
                vc.selectedTweet = dataController.tweetsArray[indexPath.row]
            }
        }
    }
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



