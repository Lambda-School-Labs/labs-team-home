//
//  MessageBoardViewController.swift
//  TeamHome
//
//  Created by Daniela Parra on 1/10/19.
//  Copyright © 2019 Lambda School under the MIT license. All rights reserved.
//

import UIKit
import Apollo

protocol MessageBoardFilterDelegate: class {
    func didClickFilter()
    var newestToOldest: Bool { get set }
}

class MessageBoardViewController: UIViewController, TabBarChildrenProtocol {
    
    // MARK - Lifecycle Methods

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setUpViewAppearance()
        createGradientLayer()
        teamNameLabel.textColor = Appearance.yellowColor
        
        // Show team name on label
        displayTeamInfo()
    }
    
    // Filter messages by date.
    @IBAction func filterMessages(_ sender: Any) {
        guard let delegate = delegate else { return }
        
        if delegate.newestToOldest {
            let image = UIImage(named: "Arrow Down")!
            filterButton.setImage(image, for: .normal)
        } else {
            let image = UIImage(named: "Arrow Up")!
            filterButton.setImage(image, for: .normal)
        }
        
        delegate.didClickFilter()
    }
    
    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        guard let apollo = apollo,
            let team = team else { return }
        
        // Pass Apollo Client and team info to Team Detail VC, Messages Container View and Add New Message VC
        if segue.identifier == "ViewTeam" {
            guard let destinationVC = segue.destination as? TeamDetailTableViewController else { return }
            
            destinationVC.apollo = apollo
            destinationVC.team = team
        } else if segue.identifier == "EmbeddedMessages" {
            guard let destinationVC = segue.destination as? MessagesCollectionViewController else { return }
            
            destinationVC.apollo = apollo
            destinationVC.team = team
            self.delegate = destinationVC
        } else if segue.identifier == "AddMessage" {
            guard let destinationVC = segue.destination as? AddEditMessageViewController else { return }
            
            destinationVC.apollo = apollo
            destinationVC.team = team
        }
    }
    
    // MARK - Private Methods
    
    // Display team name at the top of the view
    private func displayTeamInfo() {
        guard let team = team else { return }
        
        teamNameLabel.text = team.name
        
    }
    
    func createGradientLayer() {
        gradientLayer = CAGradientLayer()
        
        gradientLayer.frame = self.view.bounds
        
        gradientLayer.colors = [Appearance.grayColor.cgColor, Appearance.likeGrayColor.cgColor, Appearance.grayColor.cgColor]
        
        
        gradientLayer.locations = [0.0, 0.5]
        gradientLayer.startPoint = CGPoint(x: 0.0, y: 0.0)
        gradientLayer.endPoint = CGPoint(x: 1.0, y: 1.0)
        
        self.view.layer.insertSublayer(gradientLayer, at: 0)
    }
    
    // MARK - Properties
    
    private var gradientLayer: CAGradientLayer!
    var team: FindTeamsByUserQuery.Data.FindTeamsByUser?
    var apollo: ApolloClient?
    var delegate: MessageBoardFilterDelegate?
    
    @IBOutlet weak var teamNameLabel: UILabel!
    @IBOutlet weak var filterButton: UIButton!

}
