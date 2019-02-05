//
//  AddNewMessageViewController.swift
//  TeamHome
//
//  Created by Daniela Parra on 1/11/19.
//  Copyright © 2019 Lambda School under the MIT license. All rights reserved.
//

import UIKit
import Apollo
import Cloudinary
import Photos
import Material
import TagListView

// Set up cloudinary with account details for all app to use
let config = CLDConfiguration(cloudName: "massamb", secure: true)
let cloudinary = CLDCloudinary(configuration: config)

class AddEditMessageViewController: UIViewController,  UIImagePickerControllerDelegate, UINavigationControllerDelegate, TagListViewDelegate {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setUpViewAppearance()
        newMessageView.backgroundColor = Appearance.plumColor
        cancelButton.tintColor = Appearance.yellowColor
        Appearance.styleLandingPage(button: submitButton)
        messageContentTextView.placeholder = "Enter your message"
        messageContentTextView.tintColor = .white
        messageTitleTextField.placeholderActiveColor = Appearance.yellowColor
        messageTitleTextField.dividerActiveColor = Appearance.yellowColor
        tagListView.delegate = self
        
        updateViews()
        
        guard let apollo = apollo,
            let team = team,
            let teamId = team.id else { return }
        
        fetchAllTags(with: apollo, for: teamId)
    }
    
    // MARK - IBActions
    
    // Let user select photo from photo library to add to new message
    @IBAction func addPhoto(_ sender: Any) {
        // Get authorization status
        let status = PHPhotoLibrary.authorizationStatus()
        
        switch status {
        // If status is already authorized, present the image picker to the user
        case .authorized:
            presentImagePickerController()
        // If status is not determined, request authorization and check status again
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization { (authorizationStatus) in
                
                switch authorizationStatus {
                // If user authorizes, present the image picker to the user
                case .authorized:
                    self.presentImagePickerController()
                case .notDetermined:
                    // Present alert
                    break
                case .restricted:
                    // Present alert
                    break
                case .denied:
                    // Present alert
                    break
                }
            }
        // If status is already denied, present alert and direct user to change status
        case .denied:
            // Present alert
            break
        // If status is restricted, present alert to explain that they can't add photos
        case .restricted:
            // Present alert
            break
        }
    }
    
    @IBAction func createTag(_ sender: Any) {
        guard let apollo = apollo,
            let team = team,
            let teamId = team.id,
            let tag = tagsTextField.text else { return }
        
        apollo.perform(mutation: CreateNewTagMutation(name: tag, teamId: teamId), queue: DispatchQueue.global()) { (result, error) in
            if let error = error {
                print("\(error)")
                return
            }
            
            guard let result = result,
                let data = result.data,
                let tag = data.addTag else { return }
            
            print(tag)
            
            self.tagsWatcher?.refetch()
            
            DispatchQueue.main.async {
                self.tagsTextField.text = ""
                
                // Show tag alert?
            }
        }
    }
    
    // Create or update message.
    @IBAction func submitMessage(_ sender: Any) {
        
        // Unwrap apollo client and other message details.
        guard let apollo = apollo,
            let team = team,
            let teamId = team.id,
            let messageTitle = messageTitleTextField.text,
            let content = messageContentTextView.text,
            let tagId = findSelectedTag() else { return }
        
        // Check if message already exists.
        guard let message = message,
            let messageId = message.id else {
                
            // Create a new message.
            createNewMessage(with: apollo, messageTitle: messageTitle, teamId: teamId, content: content, tagId: tagId)
            return
        }
        
        // Update message.
        updateMessage(with: apollo, messageId: messageId, messageTitle: messageTitle, teamId: teamId, content: content, tagId: tagId)
        
    }
    
    // Cancel create new message and return to message board.
    @IBAction func cancelNewMessage(_ sender: Any) {
//        // For modal segue
//        self.dismiss(animated: true, completion: nil)
        
        navigationController?.popViewController(animated: true)
    }
    
    // MARK - UIImagePickerControllerDelegate
    
    @objc func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        picker.dismiss(animated: true, completion: nil)
        
        guard let image = info[.originalImage] as? UIImage else { return }
        
        imageView.isHidden = false
        imageView.image = image
        guard let imageData: Data = image.jpegData(compressionQuality: 0) else { return }
        self.imageData = imageData
        
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    
    // MARK - TagListViewDelegate
    
    func tagPressed(_ title: String, tagView: TagView, sender: TagListView) {
        print(title)
    }
    
    // MARK - Private Methods
    
    private func updateViews() {
        guard isViewLoaded,
            let message = message else { return }
        
        messageTitleTextField.text = message.title
        messageContentTextView.text = message.content
        
        guard let images = message.images else { return }
        
        // Only grabs first photo.
        if images.count > 0 {
            guard let image = images.first,
                let imageURL = image else { return }
            
            self.imageURL = imageURL
            
            cloudinary.createDownloader().fetchImage(imageURL, { (progress) in
                // Show progress
                
            }) { (image, error) in
                if let error = error {
                    print("\(error)")
                    return
                }
                
                guard let image = image else { return }
                
                DispatchQueue.main.async {
                    self.imageView.isHidden = false
                    self.imageView.image = image
                }
                
            }
        }
        
        // If no image is included in message, set imageURL to nil.
        self.imageURL = nil
    }
    
    private func fetchAllTags(with apollo: ApolloClient, for teamId: GraphQLID) {
        // Find all tags by current team
        tagsWatcher = apollo.watch(query: FindTagsByTeamQuery(teamId: teamId)) { (result, error) in
            if let error = error {
                NSLog("\(error)")
                return
            }
            
            guard let result = result,
                let data = result.data,
                let tags = data.findTagsByTeam else { return }
            
            // Save tags and populate collection view
            print(tags)
            self.setUpTagListView(for: tags)
            self.tags = tags
        }
    }
    
    private func setUpTagListView(for tags: [FindTagsByTeamQuery.Data.FindTagsByTeam?]) {
        
        let tagStrings = tags.compactMap({ $0?.name })
        
        tagListView.alignment = .center
        tagListView.addTags(tagStrings)
    }
    
    private func createNewTag(with apollo: ApolloClient,under teamId: GraphQLID, for string: String) {
        apollo.perform(mutation: CreateNewTagMutation(name: string, teamId: teamId), queue: DispatchQueue.global(), resultHandler: { (result, error) in
            if let error = error {
                NSLog("\(error)")
            }
            
            guard let result = result,
                let newTagId = result.data?.addTag?.id else { return }
            
            print(newTagId)
            
        })
    }
    
    private func presentImagePickerController() {
        
        let imagePicker = UIImagePickerController()
        
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
            imagePicker.delegate = self
            imagePicker.sourceType = .photoLibrary
            present(imagePicker, animated: true, completion: nil)
        }
    }
    
    private func findSelectedTag() -> GraphQLID? {
        // Unwrap tag selection or recently created tag
        let selectedTags = tagListView.selectedTags()
        
        guard let selectedTag = selectedTags.first,
            let selectedLabel = selectedTag.titleLabel,
            let selectedString = selectedLabel.text,
            let tags = tags else { return nil }
        
        for tag in tags {
            if let tag = tag {
                if tag.name == selectedString {
                    return tag.id
                }
            }
        }
        
        return nil
    }
    
    private func createNewMessage(with apollo: ApolloClient, messageTitle: String, teamId: GraphQLID, content: String, tagId: String) {
        
        // Check to see if user selected image.
        guard let imageData = imageData else {
            
            // If no photo is selected, create message without images attached.
            apollo.perform(mutation: AddNewMessageMutation(title: messageTitle, team: teamId, content: content, images: nil, tagId: tagId), queue: DispatchQueue.global()) { (result, error) in
                // Check for errors.
                if let error = error {
                    NSLog("\(error)")
                    return
                }
                
                guard let result = result,
                    let data = result.data,
                    let message = data.addMessage else { return }
                
                print(message.title)
                
                DispatchQueue.main.async {
                    // Call messages watcher to refetch all messages.
                    messagesWatcher?.refetch()
                    // Go back to previous view controller.
                    self.navigationController?.popViewController(animated: true)
                }
            }
            return
        }
        
        // If photo is selected, create new message with photo.
        
        // Set up upload request parameters.
        let params = CLDUploadRequestParams()
        
        // Upload image to cloudinary.
        cloudinary.createUploader().upload(data: imageData, uploadPreset: "dfcfme0b", params: params, progress: { (progress) in
            //Show progress.
            
        }) { (result, error) in
            // Check for errors.
            if let error = error {
                NSLog("\(error)")
                return
            }
            
            // Unwrap image url.
            guard let result = result,
                let url = result.url else { return }
            
            // Pass image url to Apollo client to create message.
            apollo.perform(mutation: AddNewMessageMutation(title: messageTitle, team: teamId, content: content, images: [url]), queue: DispatchQueue.global()) { (result, error) in
                // Check for errors.
                if let error = error {
                    NSLog("\(error)")
                    return
                }
                
                guard let result = result,
                    let data = result.data,
                    let message = data.addMessage else { return }
                
                print(message.title)
                
                DispatchQueue.main.async {
                    // Call messages watcher to refetch all messages.
                    messagesWatcher?.refetch()
                    // Go back to previous view controller.
                    self.navigationController?.popViewController(animated: true)
                }
            }
        }
    }
    
    private func updateMessage(with apollo: ApolloClient, messageId: GraphQLID, messageTitle: String, teamId: GraphQLID, content: String, tagId: String) {
        
        // Check to see if user selected image.
        guard let imageData = imageData else {
            
            // Check for existing image url
            
            apollo.perform(mutation: UpdateMessageMutation(id: messageId, title: messageTitle, teamId: teamId, content: content, images: [""], tagId: tagId), queue: DispatchQueue.global()) { (result, error) in
                // Check for errors.
                if let error = error {
                    NSLog("\(error)")
                    return
                }
                
                guard let result = result,
                    let data = result.data,
                    let message = data.updateMessage else { return }
                
                print(message.title)
                
                DispatchQueue.main.async {
                    // Call messages watcher to refetch all messages.
                    messagesWatcher?.refetch()
                    // Go back to previous view controller.
                    self.navigationController?.popViewController(animated: true)
                }
            }
            return
        }
        
        // If photo is selected, create new message with photo.
        
        // Set up upload request parameters.
        let params = CLDUploadRequestParams()
        
        // Upload image to cloudinary.
        cloudinary.createUploader().upload(data: imageData, uploadPreset: "dfcfme0b", params: params, progress: { (progress) in
            //Show progress.
            
        }) { (result, error) in
            // Check for errors.
            if let error = error {
                NSLog("\(error)")
                return
            }
            
            // Unwrap image url.
            guard let result = result,
                let url = result.url else { return }
            
            apollo.perform(mutation: UpdateMessageMutation(id: messageId, title: messageTitle, teamId: teamId, content: content, images: [url], tagId: tagId), queue: DispatchQueue.global()) { (result, error) in
                // Check for errors.
                if let error = error {
                    NSLog("\(error)")
                    return
                }
                
                guard let result = result,
                    let data = result.data,
                    let message = data.updateMessage else { return }
                
                print(message.title)
                
                DispatchQueue.main.async {
                    // Call messages watcher to refetch all messages.
                    messagesWatcher?.refetch()
                    // Go back to previous view controller.
                    self.navigationController?.popViewController(animated: true)
                }
            }
        }
    }
    
    // MARK - Properties
    
    private var imageURL: String?
    private var imageData: Data?
    private var tags: [FindTagsByTeamQuery.Data.FindTagsByTeam?]?
    private var tagsWatcher: GraphQLQueryWatcher<FindTagsByTeamQuery>?
    
    var apollo: ApolloClient?
    var team: FindTeamsByUserQuery.Data.FindTeamsByUser?
    var message: FindMessageByIdQuery.Data.FindMessage? {
        didSet {
            DispatchQueue.main.async {
                self.updateViews()
            }
        }
    }
    
    @IBOutlet weak var cancelButton: FlatButton!
    @IBOutlet weak var submitButton: RaisedButton!
    @IBOutlet weak var newMessageView: UIView!
    @IBOutlet weak var messageTitleTextField: TextField!
    @IBOutlet weak var messageContentTextView: TextView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var tagListView: TagListView!
    @IBOutlet weak var tagsTextField: UITextField!
    
}