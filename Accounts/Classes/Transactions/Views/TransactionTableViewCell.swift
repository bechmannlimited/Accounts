//
//  TransactionTableViewCell.swift
//  Accounts
//
//  Created by Alex Bechmann on 15/08/2015.
//  Copyright (c) 2015 Alex Bechmann. All rights reserved.
//

import UIKit
 

let kPurchaseImage = AppTools.iconAssetNamed("1007-price-tag-toolbar.png")
//private let kTransactionImage =AppTools.iconAssetNamed("922-suitcase-toolbar.png")
let kPaymentImage = AppTools.iconAssetNamed("826-money-1-toolbar")
let kIouImage = AppTools.iconAssetNamed("922-suitcase-toolbar.png")
let kSecureImage = AppTools.iconAssetNamed("744-locked-toolbar")

class TransactionTableViewCell: UITableViewCell {

    var dateLabel: UILabel = UILabel()
    var transaction = Transaction()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func setupCell(transaction: Transaction) {
        
        self.transaction = transaction
        
        let amount = transaction.localeAmount
        //let dateString:String = transaction.transactionDate.toString(DateFormat.Date.rawValue)
        let tintColor = transaction.toUser?.objectId == User.currentUser()?.objectId ? AccountColor.negativeColor() : AccountColor.positiveColor()
        let amountText = Formatter.formatCurrencyAsString(abs(amount))
        var iouText = ""
        
        detailTextLabel?.textColor = tintColor

        if transaction.type == TransactionType.payment {
            
            imageView?.image = kPaymentImage
            iouText = transaction.fromUser == User.currentUser() ? "You paid \(transaction.toUser!.firstName) \(amountText)" : "\(transaction.fromUser!.firstName) paid you \(amountText)"
        }
        else if transaction.type == TransactionType.iou {
            
            imageView?.image = kIouImage
            iouText = transaction.fromUser == User.currentUser() ? "\(transaction.toUser!.firstName) owes you \(amountText)" : "You owe \(amountText)"
        }
        
        if transaction.purchaseTransactionLinkUUID != nil {
            
            imageView?.image = kPurchaseImage
        }
        
        imageView?.tintWithColor(tintColor)
        textLabel?.text = "\(transaction.title!)"
        detailTextLabel?.text = iouText
        accessoryType = UITableViewCellAccessoryType.DisclosureIndicator
        
        // if secure
        if transaction.isSecure {
            
            secureCell()
        }
        
        dateLabel.frame = CGRect(x: 0, y: 0, width: 100, height: 50)
        dateLabel.font = UIFont.lightFont(14)
        dateLabel.textAlignment = .Right
        dateLabel.textColor = UIColor.grayColor()
        dateLabel.text = transaction.transactionDate.readableFormattedStringForDateRange()
        
        dateLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(dateLabel)
        
        dateLabel.addRightConstraint(toView: contentView, relation: .Equal, constant: 0)
        dateLabel.addTopConstraint(toView: contentView, relation: .Equal, constant: 0)
        dateLabel.addBottomConstraint(toView: contentView, relation: .Equal, constant: 0)
        dateLabel.addWidthConstraint(relation: .Equal, constant: 100)
        
        textLabel?.font = UIFont.normalFont(textLabel!.font.pointSize)
        detailTextLabel?.font = UIFont.normalFont(detailTextLabel!.font.pointSize)
    }
    
    func secureCell() {
        
        imageView?.image = kSecureImage
        imageView?.tintWithColor(UIColor.darkGrayColor())
        
        textLabel?.text = "************"
        detailTextLabel?.text = "********"
        
//        let blurView = UIVisualEffectView(effect: UIBlurEffect(style: UIBlurEffectStyle.Light))
//        blurView.translatesAutoresizingMaskIntoConstraints = false
//        contentView.addSubview(blurView)
//        
//        blurView.layer.shouldRasterize = true
//        blurView.layer.rasterizationScale = UIScreen.mainScreen().scale
//        
//        blurView.fillSuperView(UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 50))
        
        contentView.bringSubviewToFront(imageView!)
    }
    
    var originalTextLabelFrame: CGRect?
    var originalDetailTextLabelFrame: CGRect?
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if originalDetailTextLabelFrame == nil {
            
            originalTextLabelFrame = textLabel?.frame
            originalDetailTextLabelFrame = detailTextLabel?.frame
        }
        
        if let originalTextLabelFrame = originalTextLabelFrame {
            
            textLabel?.frame = CGRect(x: originalTextLabelFrame.origin.x, y: originalTextLabelFrame.origin.y, width: contentView.frame.width - 135, height: originalTextLabelFrame.height)
        }
        
        if let originalDetailTextLabelFrame = originalDetailTextLabelFrame {
            
            detailTextLabel?.frame = CGRect(x: originalDetailTextLabelFrame.origin.x, y: originalDetailTextLabelFrame.origin.y, width: contentView.frame.width - 135, height: originalDetailTextLabelFrame.height)
        }
    }

}
