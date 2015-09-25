//
//  FriendTableViewCell.swift
//  Accounts
//
//  Created by Alex Bechmann on 02/08/2015.
//  Copyright (c) 2015 Alex Bechmann. All rights reserved.
//

import UIKit
import ABToolKit
import KFSwiftImageLoader

private let kContentViewVerticalPadding: CGFloat = 10
private let kContentViewHorizontalPadding: CGFloat = 15
private let kContentViewGap: CGFloat = 15

protocol FriendTableViewCellDelegate {
    
    func didRemoveFriend(friend: User, indexPath: NSIndexPath?)
}

class FriendTableViewCell: UITableViewCell {

    var friend: User!
    
    var friendImageView = UIImageView()
    var friendNameLabel = UILabel()
    var amountOwedLabel = UILabel()
    var contextualTintColor = UIColor.grayColor()
    var noImageLabel = UILabel()
    var friendImageViewConstraints = Dictionary<String, NSLayoutConstraint>()
    var delegate: FriendTableViewCellDelegate?
    var currentIndexPath: NSIndexPath?
    
    convenience init(reuseIdentifier:String) {
        
        self.init(style: UITableViewCellStyle.Value1, reuseIdentifier: reuseIdentifier)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        //friendNameLabel.removeConstraints(friendNameLabel.constraints())
        //friendImageView.removeConstraints(friendNameLabel.constraints())
        //amountOwedLabel.removeConstraints(friendNameLabel.constraints())
        
        setupImageView()
        setupFriendNameLabel()
        
        textLabel?.font = UIFont.normalFont(textLabel!.font.pointSize)
        detailTextLabel?.font = UIFont.lightFont(detailTextLabel!.font.pointSize)
    }
    
    override func drawRect(rect: CGRect){
        super.drawRect(rect)
        
        friendNameLabel.setTranslatesAutoresizingMaskIntoConstraints(false)
        contentView.addSubview(friendNameLabel)
        
        friendImageView.setTranslatesAutoresizingMaskIntoConstraints(false)
        contentView.addSubview(friendImageView)
        
        amountOwedLabel.setTranslatesAutoresizingMaskIntoConstraints(false)
        contentView.addSubview(amountOwedLabel)
        
        accessoryType = UITableViewCellAccessoryType.DisclosureIndicator
    }
    
    func setup(friend:User) {
        
        self.friend = friend
        setImageViewImage()
        setupLabelValues()
        setupGestureRecognizer()
    }
    
    func setImageViewImage(){
        
        calculateTintColor()
        
        if friendImageView.image == nil { // for now as each cell is separetely initialized
            
            friendImageView.image = UIImage.imageWithColor(.clearColor(), size: CGSize(width: 1, height: 1))
            friendImageView.tintWithColor(tintColor)
            friendImageView.clipsToBounds = true
            
            let completionHandler: () -> () = {
                
                self.friendImageView.hideLoader()
                self.friendImageView.contentMode = UIViewContentMode.ScaleAspectFill
                //self.friendImageView.image = image
                self.friendImageView.layer.cornerRadius = self.friendImageViewWidth() / 2
            }
            
            if friend.objectId == kTestBotObjectId {
                
                friendImageView.image = AppTools.iconAssetNamed("50981152_thumbnail.jpg")
                completionHandler()
            }
            else if let id = friend.facebookId {
                
                friendImageView.showLoader()
                
                let url = "https://graph.facebook.com/\(id)/picture?width=\(150)&height=\(150)"

                ABImageLoader.sharedLoader().loadImageFromCacheThenNetwork(url, completion: { (image) -> () in
                    
                    self.friendImageView.image = image
                    completionHandler()
                })
            }
        }
    }
    
    private func showNoImageLabel() {
        
        noImageLabel.setTranslatesAutoresizingMaskIntoConstraints(false)
        friendImageView.addSubview(noImageLabel)
        
        noImageLabel.fillSuperView(UIEdgeInsetsZero)
        
        noImageLabel.lineBreakMode = NSLineBreakMode.ByWordWrapping
        noImageLabel.numberOfLines = 0
        noImageLabel.text = "NO IMAGE"
        noImageLabel.font = UIFont.systemFontOfSize(12)
        noImageLabel.textAlignment = NSTextAlignment.Center
    }
    
    func setupLabelValues() {
        
        friendNameLabel.text = friend.appropriateDisplayName()
        let amount = abs(friend.localeDifferenceBetweenActiveUser) //abs()
        
        detailTextLabel?.text = Formatter.formatCurrencyAsString(amount)
        detailTextLabel?.textColor = contextualTintColor
    }
    
    func setupGestureRecognizer() {
        
        if friend.objectId != kTestBotObjectId {
            
            let gestureRecognizer = UILongPressGestureRecognizer(target: self, action: "showFriendOptions:")
            addGestureRecognizer(gestureRecognizer)
        }
    }
    
    func setupActionSheet() {
        
        
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
            (alert: UIAlertAction!) -> Void in
            
        })
        
        optionMenu.addAction(deleteAction)
        optionMenu.addAction(cancelAction)
        
        optionMenu.popoverPresentationController!.sourceView = self.contentView
        optionMenu.popoverPresentationController?.sourceRect = CGRect(x: 0, y: 0, width: 70, height: contentView.frame.height)
        
        if gestureRecognizor.state == UIGestureRecognizerState.Began {
            
            UIViewController.topMostController().presentViewController(optionMenu, animated: true, completion: nil)
        }
    }
    
    func calculateTintColor() {
        
        contextualTintColor = UIColor.grayColor()
        
        if friend.localeDifferenceBetweenActiveUser.roundToPlaces(2) < 0 {
            
            contextualTintColor = AccountColor.negativeColor()
        }
        else if friend.localeDifferenceBetweenActiveUser.roundToPlaces(0) > 0 {
            
            contextualTintColor = AccountColor.positiveColor()
        }
    }
    
    
    // MARK: - Constraints
    
    func setupImageView() {
        
        friendImageView.addLeftConstraint(toView: contentView, relation: .Equal, constant: kContentViewHorizontalPadding)
        friendImageView.addCenterYConstraint(toView: contentView)
        friendImageViewConstraints["Width"] = friendImageView.addWidthConstraint(relation: .Equal, constant:friend.facebookId != nil || friend.objectId == kTestBotObjectId ? friendImageViewWidth() : 0)
        friendImageView.addTopConstraint(toView: contentView, attribute: NSLayoutAttribute.Top, relation: NSLayoutRelation.GreaterThanOrEqual, constant: kContentViewVerticalPadding)
        friendImageView.addBottomConstraint(toView: contentView, attribute: NSLayoutAttribute.Bottom, relation: NSLayoutRelation.GreaterThanOrEqual, constant: -kContentViewVerticalPadding)

        friendImageView.clipsToBounds = true
    }
    
    func setupFriendNameLabel() {
        
        friendNameLabel.addLeftConstraint(toView: friendImageView, attribute: .Right, relation: .Equal, constant: kContentViewGap)
        friendNameLabel.addTopConstraint(toView: contentView, relation: .Equal, constant: kContentViewVerticalPadding)
        friendNameLabel.addBottomConstraint(toView: contentView, relation: .Equal, constant: -kContentViewVerticalPadding)
        friendNameLabel.addRightConstraint(toView: detailTextLabel, attribute: .Left, relation: .Equal, constant: kContentViewGap)
    }
    
    func setupAmountOwedLabel() {

        amountOwedLabel.addLeftConstraint(toView: friendNameLabel, attribute: NSLayoutAttribute.Right, relation: NSLayoutRelation.Equal, constant: kContentViewGap)
        amountOwedLabel.addTopConstraint(toView: contentView, relation: .Equal, constant: kContentViewHorizontalPadding)
        amountOwedLabel.addBottomConstraint(toView: contentView, relation: .Equal, constant: -kContentViewVerticalPadding)
        amountOwedLabel.addRightConstraint(toView: contentView, relation: .Equal, constant: -5)
    }
    
    private func friendImageViewWidth() -> CGFloat{
        //println(contentView.frame.height - (kContentViewVerticalPadding * 2))
        //return contentView.frame.height - (kContentViewVerticalPadding * 2)
        return 49.5
    }
}
