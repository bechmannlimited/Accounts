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

class FriendTableViewCell: UITableViewCell {

    var friend: User!
    
    var friendImageView = UIImageView()
    var friendNameLabel = UILabel()
    var amountOwedLabel = UILabel()
    var contextualTintColor = UIColor.grayColor()
    var noImageLabel = UILabel()
    var friendImageViewConstraints = Dictionary<String, NSLayoutConstraint>()
    
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
                
                friendImageView.image = AppTools.iconAssetNamed("bender.jpg")
                completionHandler()
            }
            else if let id = friend.facebookId {
                
                friendImageView.showLoader()
                
                let url = "https://graph.facebook.com/\(id)/picture?width=\(150)&height=\(150)"
                
                friendImageView.loadImageFromURLString(url, placeholderImage: nil) {
                    (finished, error) in
                    
                    completionHandler()
                }
                
//                ABImageLoader.loadImageFromCacheThenNetwork(url, completion: { (image) -> () in
//                    
//                    completionHandler(image: image)
//                })
                
//                ImageLoader.sharedLoader().imageForUrl(url, completionHandler: { (image, url) -> () in
//                    
//                    if let image = image {
//                        
//                        completionHandler(image: image)
//                    }
//                    
//                    if image == nil {
//                        
//                        ABImageLoader.loadImageFromCacheThenNetwork(url, completion: { (image) -> () in
//                            
//                            completionHandler(image: image)
//                        })
//                    }
//                })
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
        let amount = friend.localeDifferenceBetweenActiveUser //abs()
        
        detailTextLabel?.text = Formatter.formatCurrencyAsString(amount)
        detailTextLabel?.textColor = contextualTintColor
    }
    
    func calculateTintColor() {
        
        contextualTintColor = UIColor.grayColor()
        
        if friend.localeDifferenceBetweenActiveUser < 0 {
            
            contextualTintColor = AccountColor.negativeColor()
        }
        else if friend.localeDifferenceBetweenActiveUser > 0 {
            
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
