//
//  ActiveFiltersController.swift
//  Elonidas
//
//  Created by Ondrej Winter on 09.04.2021.
//

import Foundation
import UIKit
import Firebase

class ActiveFiltersController: UIViewController {
    
    var dataController: DataController!
    var user: User?
    var filteredTwitterUsernames: [DataSnapshot] = []
    var storageRef: StorageReference!
    let imageCache = NSCache<NSString, UIImage>()
    
    
    @IBOutlet weak var filtersTableView: UITableView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        user = myAuth.user
        filteredTwitterUsernames = dataController.filteredUsernames
        filtersTableView.delegate = self
        filtersTableView.dataSource = self
        filtersTableView.reloadData()
        
        self.filtersTableView.rowHeight = UITableView.automaticDimension
        self.filtersTableView.estimatedRowHeight = 122.0
        configureStorage()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        filteredTwitterUsernames = dataController.filteredUsernames
        filtersTableView.reloadData()
    }
    
    func configureStorage() {
        storageRef = Storage.storage().reference()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "addFilter" {
            let controller = segue.destination as! AddFilterController
            controller.dataController = dataController
        }
    }
    
    @IBAction func addFilterButtonTapped(_ sender: Any) {
        performSegue(withIdentifier: "addFilter", sender: sender)
    }

    
    func deleteAFilter(indexPath: IndexPath, tableView: UITableView) {
        let twUsername = filteredTwitterUsernames[indexPath.row]
        let unwrappedTwUsername = twUsername.value as! [String:String]
        let username = unwrappedTwUsername[Constants.Filters.twUsername]
        if let uid = self.user?.uid {
            if let username = username {
                self.dataController.ref.child("users").child("\(uid)").child("tweetsIdsByUsernames").child("\(username)").child("ids").getData { (error, snapshot) in
                    if let error = error {
                        DispatchQueue.main.async {
                            Alert.showAlert(viewController: self, title: "Alert", message: "We couldn't delete the filter. Please try again.", actionTitle: "OK", style: .default)
                        }
                    }
                    else if snapshot.exists() {

                        let snap = snapshot.value as! [String: Any]
                        
                        for id in snap.keys {
                            let index = self.dataController.tweetsArray.firstIndex(where: { $0.tweetId == id })
                            if let index = index {
                                self.dataController.ref.child("users").child("\(uid)").child("allTweets").child("\(id)").removeValue()
                                self.dataController.tweetsArray.remove(at: index)
                            }

                        }
                        self.dataController.ref.child("users").child("\(uid)").child("tweetsIdsByUsernames").child("\(username)").removeValue()
                        self.dataController.ref.child("users").child("\(uid)").child("filteredTwitterUsernames").child("\(username)").removeValue()
                        let storageImagePath = "filtered_users_photos/" + Auth.auth().currentUser!.uid + "/" + username + "/" + username + ".jpg"
                        print("storageImagePath is \(storageImagePath)")
                        self.storageRef.child(storageImagePath).delete { error in
                            if let error = error {
                                // Uh-oh, an error occurred!
                                print(error)
                            } else {
                                print("File deleted successfully")
                            }
                        }
                        
                        
                        func deletingImageFromStorage(){
                            let storage = Storage.storage()
                            var storageRef = storage.reference()
                            
                            // Create a reference to the file we want to download
                            storageRef = storageRef.child("images/car.jpg")
                            
                            storageRef.delete { error in
                                if let error = error {
                                    // Uh-oh, an error occurred!
                                } else {
                                    print("File deleted successfully")
                                }
                            }
                            
                        }
                        
                        
                        self.filteredTwitterUsernames.remove(at: indexPath.row)
                        self.dataController.filteredUsernames.remove(at: indexPath.row)
                        DispatchQueue.main.async {
                            tableView.deleteRows(at: [indexPath], with: .automatic)
                        }
                        
                    } else {
                        self.dataController.ref.child("users").child("\(uid)").child("filteredTwitterUsernames").child("\(username)").removeValue()
                        let storageImagePath = "filtered_users_photos/" + Auth.auth().currentUser!.uid + "/" + username + "/" + username + ".jpg"
                        print("storageImagePath is \(storageImagePath)")
                        self.storageRef.child(storageImagePath).delete { error in
                            if let error = error {
                                // Uh-oh, an error occurred!
                                print(error)
                            } else {
                                print("File deleted successfully")
                            }
                        }
                        self.filteredTwitterUsernames.remove(at: indexPath.row)
                        self.dataController.filteredUsernames.remove(at: indexPath.row)
                        DispatchQueue.main.async {
                            tableView.deleteRows(at: [indexPath], with: .automatic)
                        }
                    }
                }
            }
        }
    }
}



extension ActiveFiltersController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredTwitterUsernames.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = filtersTableView.dequeueReusableCell(withIdentifier: "filterCell", for: indexPath)
        let snapshot = filteredTwitterUsernames[indexPath.row]
        let dictionaryFromSnapshot = snapshot.value as! [String:String]
        let username = dictionaryFromSnapshot[Constants.Filters.twUsername] ?? ""
        let filteredWord = dictionaryFromSnapshot[Constants.Filters.filteredWord] ?? ""
        cell.textLabel?.text = username + " - \"\(filteredWord)\""
        
        cell.imageView?.image = UIImage(named: "ic_account_circle")

        
        if let imageUrl = dictionaryFromSnapshot[Constants.Filters.profileImageUrl] {
            // image already exists in cache
            print("imageURL is: \(imageUrl)")
            if let cachedImage = imageCache.object(forKey: imageUrl as NSString) {

                cell.imageView?.image = cachedImage
                cell.imageView?.setRounded()
                cell.setNeedsLayout()
            } else {
                // download image
                Storage.storage().reference(forURL: imageUrl).getData(maxSize: INT64_MAX, completion: { (data, error) in
                    guard error == nil else {
                        print("Error downloading: \(error!)")
                        return
                    }
                    let profileImage = UIImage.init(data: data!, scale: 1)
                    self.imageCache.setObject(profileImage!, forKey: imageUrl as NSString)
                    // check if the cell is still on screen, if so, update cell image
                    if cell == tableView.cellForRow(at: indexPath) {
                        DispatchQueue.main.async {

                            cell.imageView?.frame = CGRect(x: 0, y: 0, width: 48, height: 48)
                            cell.imageView?.image = profileImage
                            cell.imageView?.setRounded()
                            cell.setNeedsLayout()
                        }
                    }
                })
            }
        }
 
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        switch editingStyle {
        case .delete: deleteAFilter(indexPath: indexPath, tableView: tableView)
        default: ()
        }
    }

}
