//
//  TransactionTableViewCell.swift
//  Accounts
//
//  Created by Alex Bechmann on 15/08/2015.
//  Copyright (c) 2015 Alex Bechmann. All rights reserved.
//

import UIKit
import ABToolKit

private let kPurchaseImage = AppTools.iconAssetNamed("1007-price-tag-toolbar.png")
private let kTransactionImage = AppTools.iconAssetNamed("922-suitcase-toolbar.png")
private let kPaymentImage = AppTools.iconAssetNamed("384-dollar-currency")

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
        
        var amount = transaction.localeAmount
        
        let dateString:String = transaction.transactionDate.toString(DateFormat.Date.rawValue)
        
        let tintColor = transaction.toUser?.objectId == User.currentUser()?.objectId ? AccountColor.negativeColor() : AccountColor.positiveColor()
        
        detailTextLabel?.textColor = tintColor
        
        let amountText = Formatter.formatCurrencyAsString(abs(amount))
        
        var iouText = ""
        
        if transaction.type == TransactionType.payment {
            
            imageView?.image = kTransactionImage
            iouText = transaction.fromUser == User.currentUser() ? "You paid \(transaction.toUser!.firstName) \(amountText)" : "\(transaction.fromUser!.firstName) paid you \(amountText)"
        }
        else if transaction.type == TransactionType.iou {
            
            imageView?.image = kTransactionImage
            iouText = transaction.fromUser == User.currentUser() ? "\(transaction.toUser!.firstName) owes you \(amountText)" : "You owe \(amountText)"
        }
        
        imageView?.tintWithColor(tintColor)
        textLabel?.text = "\(transaction.title!)"
        detailTextLabel?.text = iouText
        accessoryType = UITableViewCellAccessoryType.DisclosureIndicator
        
        dateLabel.frame = CGRect(x: 0, y: 0, width: 100, height: 50)
        dateLabel.font = UIFont.lightFont(14)
        //dateLabel.font = UIFont.systemFontOfSize(14)
        dateLabel.textAlignment = .Right
        dateLabel.textColor = UIColor.grayColor()
        dateLabel.text = transaction.transactionDate.readableFormattedStringForDateRange()
        
        dateLabel.setTranslatesAutoresizingMaskIntoConstraints(false)
        contentView.addSubview(dateLabel)
        
        dateLabel.addRightConstraint(toView: contentView, relation: .Equal, constant: 0)
        dateLabel.addTopConstraint(toView: contentView, relation: .Equal, constant: 0)
        dateLabel.addBottomConstraint(toView: contentView, relation: .Equal, constant: 0)
        dateLabel.addWidthConstraint(relation: .Equal, constant: 100)
        
        textLabel?.frame = CGRect(x: 0, y: 0, width: textLabel!.frame.width - 100, height: textLabel!.frame.height)
        detailTextLabel?.frame = CGRect(x: 0, y: 0, width: detailTextLabel!.frame.width - 100, height: detailTextLabel!.frame.height)
        
        textLabel?.font = UIFont.normalFont(textLabel!.font.pointSize)
        detailTextLabel?.font = UIFont.normalFont(detailTextLabel!.font.pointSize)
    }

}
