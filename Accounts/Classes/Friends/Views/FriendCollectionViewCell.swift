//
//  FriendCollectionViewCell.swift
//  Accounts
//
//  Created by Alex Bechmann on 29/11/2015.
//  Copyright © 2015 Alex Bechmann. All rights reserved.
//

import UIKit

private let kPadding:CGFloat = 10
private let kCornerRadius: CGFloat = 10
private let kMultiCurrencyTableViewCellHeight: CGFloat = 30

class FriendCollectionViewCell: UICollectionViewCell {

    var friend: User!
    
    var friendImageView = UIImageView()
    var friendNameLabel = UILabel()
    var contextualTintColor = UIColor.grayColor()
    var noDataView = UIView()
    var friendImageViewConstraints = Dictionary<String, NSLayoutConstraint>()
    var delegate: FriendTableViewCellDelegate?
    var currentIndexPath: NSIndexPath?
    var currencyTableView: MultiCurrencyTableView = MultiCurrencyTableView()
    var gestureRecognizer: UILongPressGestureRecognizer?
    let noDataLabel = UILabel()
    
    var imagesForFriends = Dictionary<String, UIImage>()
    
    class func cellPadding() -> CGFloat { return kPadding }
    class func multiCurrencyTableViewCellHeight() -> CGFloat { return kMultiCurrencyTableViewCellHeight }
    
    override func drawRect(rect: CGRect) {
        super.drawRect(rect)
        
        setConstraints()
        clipsToBounds = true
        
        setupNoDataView()
        showOrHideTableOrNoDataView()
        setupNoDataLabel()
    }
    
    func setup(friend:User) {
        
        self.friend = friend
        
        setLabelValues()
        setupGestureRecognizer()
        setImageViewImage()
        setupCurrencyTable()
        setupCurrencyTableConstraints()
        
        layer.cornerRadius = kCornerRadius
        contentView.backgroundColor = .whiteColor()
        
        showOrHideTableOrNoDataView()
    }
    
    func setLabelValues() {
        
        friendNameLabel.text = friend.appropriateDisplayName()
    }
    
    func setConstraints() {
        
        setupImageView()
        setupNameLabel()
    }
    
    func getProfilePicture(completion: (image: UIImage) -> ()) {
        
        if let id = friend.objectId {
            
            if let image = imagesForFriends[id] {
                
                completion(image: image)
            }
            else {
                
                friend.getProfilePicture({ (image) -> () in
                    
                    completion(image: image)
                })
            }
        }
    }
    
    func setupNoDataLabel() {
        
        noDataLabel.translatesAutoresizingMaskIntoConstraints = false
        friendImageView.addSubview(noDataLabel)
        
        noDataLabel.fillSuperView(UIEdgeInsetsZero)
        
        noDataLabel.lineBreakMode = NSLineBreakMode.ByWordWrapping
        noDataLabel.numberOfLines = 0
        noDataLabel.text = "YOUR EVEN"
        noDataLabel.font = UIFont.systemFontOfSize(12)
        noDataLabel.textAlignment = NSTextAlignment.Right
        noDataLabel.textColor = .grayColor()
        
        noDataLabel.translatesAutoresizingMaskIntoConstraints = false
        noDataView.addSubview(noDataLabel)
        noDataLabel.fillSuperView(UIEdgeInsetsZero)
    }
    
    private func setupNoDataView() {

        contentView.addSubview(noDataView)

        noDataView.translatesAutoresizingMaskIntoConstraints = false
        noDataView.addTopConstraint(toView: friendNameLabel, attribute: .Bottom, relation: .Equal, constant: kPadding)
        noDataView.addRightConstraint(toView: contentView, relation: .Equal, constant: -kPadding)
        noDataView.addHeightConstraint(relation: .Equal, constant: 30)
        noDataView.addWidthConstraint(relation: .Equal, constant: 100)
        
        noDataView.hidden = true
    }
    
    func showOrHideTableOrNoDataView() {
        
        noDataView.hidden = true
        currencyTableView.hidden = true
        
        if friend.objectId != nil {
            
            if let data = User.currentUser()?.friendsIdsWithDifferenceWithMultipleCurrencies?[friend.objectId!] {
                
                if data.count > 0 {
                    
                    currencyTableView.hidden = false
                }
                else {
                    
                    noDataView.hidden = false
                }
            }
            else {
                
                noDataView.hidden = false
            }
        }
    }
    
    func setupCurrencyTableConstraints() {
        
        currencyTableView.separatorColor = .clearColor()
        currencyTableView.backgroundColor = .whiteColor()
        
        if let data = User.currentUser()?.friendsIdsWithDifferenceWithMultipleCurrencies?[friend.objectId!] {
            
            contentView.addSubview(currencyTableView)
            
            currencyTableView.frame = CGRect(x: 0, y: 70, width: contentView.frame.width, height: CGFloat(data.keys.count) * kMultiCurrencyTableViewCellHeight)
            
            currencyTableView.delegate = currencyTableView
            currencyTableView.dataSource = currencyTableView
            currencyTableView.tableCellHeight = kMultiCurrencyTableViewCellHeight
            
            currencyTableView.userInteractionEnabled = false
        }
    }
    
    func setupCurrencyTable() {
    
        currencyTableView.hidden = true
        
        if let results = User.currentUser()?.friendsIdsWithDifferenceWithMultipleCurrencies?[friend.objectId!] {
            
            currencyTableView.results = results
            currencyTableView.reloadData()
            currencyTableView.hidden = false
        }
    }
    
    func setImageViewImage(){
        
        //if friendImageView.image == nil { // for now as each cell is separetely initialized
            
            friendImageView.image = UIImage.imageWithColor(.clearColor(), size: CGSize(width: 1, height: 1))
            friendImageView.tintWithColor(tintColor)
            friendImageView.clipsToBounds = true
        
            let currentFriendId = friend.objectId
        
            getProfilePicture { (image) -> () in
                
                if self.friend.objectId == currentFriendId {
                    
                    self.friendImageView.image = image
                    self.friendImageView.hideLoader()
                    self.friendImageView.contentMode = UIViewContentMode.ScaleAspectFill
                    self.friendImageView.layer.cornerRadius = self.friendImageViewWidth() / 2
                }
            }
        //}
    }
    
    func setupGestureRecognizer() {
        
        if let recognizer = gestureRecognizer {
            
            removeGestureRecognizer(recognizer)
        }
        
        var isFaceBookFriend = false
        
        if let id = friend.facebookId {
            
            isFaceBookFriend = User.currentUser()?.facebookFriendIds.contains(id) == true
        }
        
        if friend.objectId != kTestBotObjectId && isFaceBookFriend  == false { // TODO: - check if is a facebook friend.
            
            gestureRecognizer = UILongPressGestureRecognizer(target: self, action: "showFriendOptions:")
            addGestureRecognizer(gestureRecognizer!)
        }
    }
    
    func showFriendOptions(gestureRecognizor: UILongPressGestureRecognizer) {
        
        let optionMenu = UIAlertController(title: nil, message: "Options for \(friend.appropriateDisplayName())", preferredStyle: .ActionSheet)
        
        let deleteAction = UIAlertAction(title: "Remove friend", style: .Destructive, handler: {
            (alert: UIAlertAction!) -> Void in
            
            UIAlertController.showAlertControllerWithButtonTitle("Remove", confirmBtnStyle: UIAlertActionStyle.Destructive, message: "Are you sure you want to remove \(self.friend.appropriateDisplayName()) from your friends list?", completion: { (response) -> () in
                
                if response == AlertResponse.Confirm {
                    
                    User.currentUser()?.removeFriend(self.friend, completion: { (success) -> () in
                        
                        self.delegate!.didRemoveFriend(self.friend, indexPath: self.currentIndexPath)
                    })
                }
            })
        })
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: {
            (alert: UIAlertAction) -> Void in
            
        })
        
        optionMenu.addAction(deleteAction)
        optionMenu.addAction(cancelAction)
        
        if kDevice == .Pad {
            
            optionMenu.popoverPresentationController!.sourceView = self.contentView
            optionMenu.popoverPresentationController?.sourceRect = CGRect(x: 0, y: 0, width: 70, height: contentView.frame.height)
        }
        
        if gestureRecognizor.state == UIGestureRecognizerState.Began {
            
            UIViewController.topMostController().presentViewController(optionMenu, animated: true, completion: nil)
        }
    }
    
    func setupImageView() {
        
        friendImageView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(friendImageView)
        
        friendImageView.addLeftConstraint(toView: contentView, relation: .Equal, constant: kPadding)
        friendImageView.addTopConstraint(toView: contentView, relation: .Equal, constant: kPadding)
        friendImageView.addWidthConstraint(relation: .Equal, constant: friendImageViewWidth())
        friendImageView.addHeightConstraint(relation: .Equal, constant: friendImageViewWidth())
        
        friendImageView.clipsToBounds = true
    }
    
    func setupNameLabel() {
        
        friendNameLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(friendNameLabel)
        
        friendNameLabel.addLeftConstraint(toView: friendImageView, attribute: .Right, relation: .Equal, constant: kPadding)
        friendNameLabel.addTopConstraint(toView: contentView, relation: .Equal, constant: kPadding)
        friendNameLabel.addHeightConstraint(relation: .Equal, constant: 26)
        friendNameLabel.addRightConstraint(toView: contentView, relation: .Equal, constant: -kPadding)
        
        friendNameLabel.textAlignment = NSTextAlignment.Right
        //friendNameLabel.textColor = .whiteColor()
        
        friendNameLabel.font = UIFont.lightFont(24)
    }
    
    private func friendImageViewWidth() -> CGFloat{
        //println(contentView.frame.height - (kContentViewVerticalPadding * 2))
        //return contentView.frame.height - (kContentViewVerticalPadding * 2)
        return 49.5
    }
    
    class func friendImageViewWidth() -> CGFloat {
        
        return 49.5
    }
}
