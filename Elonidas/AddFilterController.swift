//
//  AddFilter.swift
//  Elonidas
//
//  Created by Ondrej Winter on 17.03.2021.
//

import Foundation
import UIKit
import Firebase
import FirebaseUI
import GoogleSignIn

class AddFilterController: UIViewController, FUIAuthDelegate {
    
    var dataController: DataController!
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var filterTextfield: UITextField!
    var user: User = myAuth.user!
    var keyboardOnScreen = false
    @IBOutlet var dismissKeyboardRecognizer: UITapGestureRecognizer!
    @IBOutlet weak var addFilter: UIButton!
    var storageRef: StorageReference!

    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        usernameTextField.delegate = self
        filterTextfield.delegate = self
        configureStorage()
    }
    
    func configureStorage() {
        storageRef = Storage.storage().reference()
    }

    
    
    @IBAction func addFilterButtonTapped(_ sender: Any) {
        Spinner.start()
        addFilter.resignFirstResponder()
        if let username = usernameTextField.text {
            if let filteredText = self.filterTextfield.text {
                TwitterAPI.getUserIdByUsername(username: username) { (userData, error) in
                    if let error = error {
                        DispatchQueue.main.async {
                            Alert.showAlert(viewController: self, title: "Alert", message: "The username probably doesn't exist. Try a different one.", actionTitle: "OK", style: .default)
                        }
                    } else {
                        guard let userData = userData else {
                            return
                        }
                        
                        var data = [Constants.Filters.twUsername: username]
                        data[Constants.Filters.twUserId] = userData.id
                        data[Constants.Filters.filteredWord] = filteredText
                        let profileImageUrlString = userData.profileImageUrlString
                        

                        
                        self.downloadImage(urlString: profileImageUrlString) { imageData in
                            if let imageData = imageData {
                                self.sendImageToStorageAndImageUrlToFirebase(imageData: imageData, username: username, tweetData: data)
                            } else {
                                self.dataController.ref.child("users").child("\(self.user.uid)").child("filteredTwitterUsernames").child("\(username)").setValue(data)
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                Spinner.stop()
                                    self.navigationController?.popViewController(animated: true)
                                }

                            }
                        }
                    }

                }
                
            }
        }
        
    }
    
    func downloadImage(urlString: String, completion: @escaping(_ image: Data?) -> Void){
        
        DispatchQueue.global(qos: .userInitiated).async { () -> Void in
            
            if let url = URL(string: urlString), let imgData = try? Data(contentsOf: url) {

                DispatchQueue.main.async {
                    completion(imgData)
                }
               
            } else {
                DispatchQueue.main.async {
                    completion(nil)
                }
            }
        }
    }
    
    func sendImageToStorageAndImageUrlToFirebase(imageData: Data, username: String, tweetData: [String:String]) {
        
        let imagePath = "filtered_users_photos/" + Auth.auth().currentUser!.uid + "/" + username + "/" + username + ".jpg"
        // set content type to “image/jpeg” in firebase storage metadata
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        // create a child node at imagePath with imageData and metadata
        storageRef!.child(imagePath).putData(imageData, metadata: metadata) { (metadata, error) in
            if let error = error {
                self.dataController.ref.child("users").child("\(self.user.uid)").child("filteredTwitterUsernames").child("\(username)").setValue(tweetData)
                return
            } else {
                var mData = tweetData
                mData[Constants.Filters.profileImageUrl] = self.storageRef.child((metadata?.path)!).description
                self.dataController.ref.child("users").child("\(self.user.uid)").child("filteredTwitterUsernames").child("\(username)").setValue(mData)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    Spinner.stop()
                   self.navigationController?.popViewController(animated: true)
                }
            }
        }
    }
    
    
    
    @IBAction func tappedView(_ sender: Any) {
        resignTextfield()
    }
    
    // MARK: Show/Hide Keyboard
    
    @objc func keyboardWillShow(_ notification: Notification) {
        if !keyboardOnScreen {
            self.view.frame.origin.y -= self.keyboardHeight(notification)
        }
    }
    
    @objc func keyboardWillHide(_ notification: Notification) {
        if keyboardOnScreen {
            self.view.frame.origin.y += self.keyboardHeight(notification)
        }
    }
    
    @objc func keyboardDidShow(_ notification: Notification) {
        keyboardOnScreen = true
        dismissKeyboardRecognizer.isEnabled = true
    }
    
    @objc func keyboardDidHide(_ notification: Notification) {
        dismissKeyboardRecognizer.isEnabled = false
        keyboardOnScreen = false
    }
    
    func keyboardHeight(_ notification: Notification) -> CGFloat {
        return ((notification as NSNotification).userInfo![UIResponder.keyboardFrameBeginUserInfoKey] as! NSValue).cgRectValue.height
    }
    
    func resignTextfield() {
        if usernameTextField.isFirstResponder {
            usernameTextField.resignFirstResponder()
        }
        
        if filterTextfield.isFirstResponder {
            filterTextfield.resignFirstResponder()
        }
    }
    
}

// MARK: - FCViewController (Notifications)

extension AddFilterController {
    
    func subscribeToKeyboardNotifications() {
        subscribeToNotification(UIResponder.keyboardWillShowNotification, selector: #selector(keyboardWillShow))
        subscribeToNotification(UIResponder.keyboardWillHideNotification, selector: #selector(keyboardWillHide))
        subscribeToNotification(UIResponder.keyboardDidShowNotification, selector: #selector(keyboardDidShow))
        subscribeToNotification(UIResponder.keyboardDidHideNotification, selector: #selector(keyboardDidHide))
    }
    
    func subscribeToNotification(_ name: NSNotification.Name, selector: Selector) {
        NotificationCenter.default.addObserver(self, selector: selector, name: name, object: nil)
    }
    
    func unsubscribeFromAllNotifications() {
        NotificationCenter.default.removeObserver(self)
    }
}
    
    

extension AddFilterController: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if (string == " ") {
            return false
        }
        return true
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        textField.text = ""
    }
    
}
