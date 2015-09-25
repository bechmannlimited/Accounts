
import UIKit
import ABToolKit

private let kTitlePadding: CGFloat = 12


class BouncyHeaderView: UIView {
    
    var headerViewConstraints = Dictionary<String, NSLayoutConstraint>()
    var headerViewHeight: CGFloat = 150
    var headerViewMarginBottom: CGFloat = 20
    var originView: UIView!
    var originTableView: UITableView!
    
    let blurView = UIVisualEffectView(effect: UIBlurEffect(style: UIBlurEffectStyle.Dark))
    var heroImageView = UIImageView()
    var heroImageConstraints = Dictionary<String, NSLayoutConstraint>()
    
    var titleLabel = UILabel()
    var titleLabelHeight:CGFloat = 0
    var heightConstraint : NSLayoutConstraint?

    func setupHeaderWithOriginView(originView: UIView, originTableView: UITableView){
        
        self.originView = originView
        self.originTableView = originTableView
        
        setupOriginTableView()
        
        setupConstraints()
        
        setupHeroImage()
        setupHeroImageBlurView()
        
        userInteractionEnabled = false
        
        originView.sendSubviewToBack(self)
        
        originTableView.backgroundColor = UIColor.clearColor()
        
        backgroundColor = UIColor.blackColor()
    }
    
    func setupConstraints() {
        
        setTranslatesAutoresizingMaskIntoConstraints(false)
        originView.addSubview(self)
        
        headerViewConstraints["Top"] = addTopConstraint(toView: superview, relation: .Equal, constant: 0)
        addLeftConstraint(toView: superview, relation: .Equal, constant: 0)
        addRightConstraint(toView: superview, relation: .Equal, constant: 0)
        headerViewConstraints["Height"] = addHeightConstraint(relation: .Equal, constant: headerViewHeight)
    }
    
    func setupOriginTableView() {
        
        let insets = UIEdgeInsets(top: headerViewHeight, left: originTableView.contentInset.left, bottom: originTableView.contentInset.bottom, right: originTableView.contentInset.right)
        originTableView.contentInset = insets
    }
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        
        var y: CGFloat = scrollView.contentOffset.y + scrollView.contentInset.top
        
        if y > 0 {
            
            let h = headerViewHeight - (+y)
            headerViewConstraints["Height"]?.constant = h > 0 ? h : 0
            heroImageConstraints["Height"]?.constant = h > 0 ? h : 0
        }
            
        else{
            
            headerViewConstraints["Height"]?.constant = headerViewHeight + (-y)
            heroImageConstraints["Height"]?.constant = headerViewHeight + (-y)
        }
        
        let constant = headerViewConstraints["Height"]?.constant
        
        if constant < 64 {
            
            headerViewConstraints["Height"]?.constant = 64
            heroImageConstraints["Height"]?.constant = 64
        }
        
        //blur view
        if y < 0 {
            
            let threshhold: CGFloat = 300
            let opacity:CGFloat = -y / threshhold
            blurView.layer.opacity = 1 - Float(opacity)
        }
        else{
            
            blurView.layer.opacity = 1
        }
        
        //title
        if y > 0 {
            
            var titleOpacity: CGFloat = y / 40
            titleLabel.layer.opacity = 1 - Float(titleOpacity)
        }
        else{
            titleLabel.layer.opacity = 1
        }
    }
    
    func bounceHeaderFromPushTransition() {
        
        var transforms:[CGAffineTransform] = [
            CGAffineTransformMakeTranslation(15, 0),
            CGAffineTransformMakeTranslation(0, 0)
        ]
        
        // animation 1
        UIView.animateWithDuration(0.2, animations: { () -> Void in
            
            self.titleLabel.transform = transforms[0]
            
        }) { (finished) -> Void in
            
            UIView.animateWithDuration(0.75, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 5, options: UIViewAnimationOptions.CurveEaseInOut, animations: { () -> Void in
                
                self.titleLabel.transform = transforms[1]
                
                }, completion: { (finished) -> Void in
                    
                    
            })
        }
    }

    func setupHeroImage() {
        
        heroImageView.setTranslatesAutoresizingMaskIntoConstraints(false)
        self.addSubview(heroImageView)
        
        heroImageConstraints["Top"] = heroImageView.addTopConstraint(toView: self, relation: .Equal, constant: 0)
        heroImageConstraints["Left"] = heroImageView.addLeftConstraint(toView: self, relation: .Equal, constant: 0)
        heroImageConstraints["Right"] = heroImageView.addRightConstraint(toView: self, relation: .Equal, constant: 0)
        heroImageConstraints["Height"] = heroImageView.addHeightConstraint(relation: .Equal, constant: headerViewHeight)
        
        heroImageView.contentMode = UIViewContentMode.ScaleAspectFill
        heroImageView.clipsToBounds = true
    }
    
    func getHeroImage(url: String) {
        
        heroImageView.layer.opacity = 0
        
        ABImageLoader.sharedLoader().loadImageFromCacheThenNetwork(url, completion: { (image) -> () in
            
            self.heroImageView.image = image
            
            UIView.animateWithDuration(0.35, animations: { () -> Void in
                
                self.heroImageView.layer.opacity = 1
                
                }, completion: { (finished) -> Void in
                    
                    //self.delegate?.imageViewImageDidLoad()
            })
        })
    }
    
    func setupHeroImageBlurView() {
        
        blurView.setTranslatesAutoresizingMaskIntoConstraints(false)
        heroImageView.addSubview(blurView)
        blurView.fillSuperView(UIEdgeInsetsZero)
    }
    
    func setupTitle(title: String) {
        
        //TITLE
        //titleLabel.removeFromSuperview()
        //titleLabel = UILabel()
        
        titleLabel.setTranslatesAutoresizingMaskIntoConstraints(false)
        self.addSubview(titleLabel)
        
        let font = UIFont(name: "AppleSDGothicNeo-Bold", size: 25)! //"AppleSDGothicNeo-Bold"
        titleLabelHeight = UILabel.heightForLabel(title, font: font, width: originView.frame.width - (kTitlePadding * 2))
        //println("\(titleLabelHeight) - \(self.bounds.width - (kTitlePadding * 2))")
        
//        if let c = headerViewConstraints["title_height"] {
//            
//            titleLabel.removeConstraint(c)
//        }
        
        println(titleLabelHeight)

        titleLabel.removeConstraints(titleLabel.constraints())
        removeConstraints(titleLabel.constraints())
        heroImageView.removeConstraints(titleLabel.constraints())
        
        if let heightConstraint = heightConstraint {
            
            heightConstraint.constant = titleLabelHeight
        }
        else {
            
            heightConstraint = titleLabel.addHeightConstraint(relation: NSLayoutRelation.Equal, constant: titleLabelHeight)
        }
        
        
        titleLabel.addLeftConstraint(toView: self, relation: .Equal, constant: kTitlePadding)
        titleLabel.addRightConstraint(toView: self, relation: .Equal, constant: -kTitlePadding)
        titleLabel.addBottomConstraint(toView: heroImageView, attribute: NSLayoutAttribute.Bottom, relation: .Equal, constant: -kTitlePadding)
        
        titleLabel.text = title
        titleLabel.font = font
        titleLabel.numberOfLines = 2
        titleLabel.lineBreakMode = NSLineBreakMode.ByWordWrapping
        titleLabel.textColor = UIColor.whiteColor()
        titleLabel.textAlignment = kDevice == .Pad ? .Center : NSTextAlignment.Left
        
        titleLabel.userInteractionEnabled = false
        
        titleLabel.setNeedsUpdateConstraints()
        setNeedsUpdateConstraints()
        heroImageView.setNeedsUpdateConstraints()
    }
}