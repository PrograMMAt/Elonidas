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
    
    @IBOutlet weak var filtersTableView: UITableView!
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        user = myAuth.user
        filteredTwitterUsernames = dataController.filteredUsernames
        filtersTableView.delegate = self
        filtersTableView.dataSource = self
        filtersTableView.reloadData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        filteredTwitterUsernames = dataController.filteredUsernames
        filtersTableView.reloadData()
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
                        self.filteredTwitterUsernames.remove(at: indexPath.row)
                        self.dataController.filteredUsernames.remove(at: indexPath.row)
                        DispatchQueue.main.async {
                            tableView.deleteRows(at: [indexPath], with: .automatic)
                        }
                        
                    } else {
                        self.dataController.ref.child("users").child("\(uid)").child("filteredTwitterUsernames").child("\(username)").removeValue()
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
        return cell
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        switch editingStyle {
        case .delete: deleteAFilter(indexPath: indexPath, tableView: tableView)
        default: ()
        }
    }

}
