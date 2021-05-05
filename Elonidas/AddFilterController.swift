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
    var twUserId: String = ""
    var user: User = myAuth.user!
    var keyboardOnScreen = false
    @IBOutlet var dismissKeyboardRecognizer: UITapGestureRecognizer!
    @IBOutlet weak var addFilter: UIButton!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        usernameTextField.delegate = self
        filterTextfield.delegate = self
    }
    

    
    
    @IBAction func addFilterButtonTapped(_ sender: Any) {
        addFilter.resignFirstResponder()
        if let username = usernameTextField.text {
            if let filteredText = self.filterTextfield.text {
                TwitterAPI.getUserIdByUsername(username: username) { (userData, error) in
                    if let error = error {
                        DispatchQueue.main.async {
                            Alert.showAlert(viewController: self, title: "Alert", message: "The username probably doesn't exist. Try a different one.", actionTitle: "OK", style: .default)
                        }
                    } else {
                        guard let id = userData?.id else {
                            return
                        }
                        self.twUserId = id
                        var data = [Constants.Filters.twUsername: username]
                        data[Constants.Filters.twUserId] = self.twUserId
                        data[Constants.Filters.filteredWord] = filteredText
                        

                        self.dataController.ref.child("users").child("\(self.user.uid)").child("filteredTwitterUsernames").child("\(username)").setValue(data)
                        
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                           self.navigationController?.popViewController(animated: true)
                        }
                    }

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
