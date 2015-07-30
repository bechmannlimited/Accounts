
import UIKit
import ABToolKit

private let kTitlePadding: CGFloat = 15

class BouncyHeaderView: UIView{
    
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
    
    var delegate: BouncyViewDelegate?
    
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
        
        backgroundColor = UIColor.darkGrayColor()
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
            
            headerViewConstraints["Height"]?.constant = headerViewHeight - (+y)
            heroImageConstraints["Height"]?.constant = headerViewHeight - (+y)
        }
            
        else{
            
            headerViewConstraints["Height"]?.constant = headerViewHeight + (-y)
            heroImageConstraints["Height"]?.constant = headerViewHeight + (-y)
        }
        
        //blur view
        if y < 0 {
            
            let threshhold: CGFloat = 350
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
            println(1 - titleOpacity)
        }
        else{
            titleLabel.layer.opacity = 1
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
        
        //heroImageView.showLoader()
        
        heroImageView.layer.opacity = 0
        
        ImageLoader.sharedLoader().imageForUrl(url, completionHandler: { (image, url) -> () in
            
            self.heroImageView.image = image
            
            UIView.animateWithDuration(0.35, animations: { () -> Void in
                
                self.heroImageView.layer.opacity = 1
                
            })
            
            //self.heroImageView.hideLoader()
            
            //self.setupHeroImageBlurView()
            //self.setupTitle()
        })
        
    }
    
    func setupHeroImageBlurView() {
        
        blurView.setTranslatesAutoresizingMaskIntoConstraints(false)
        heroImageView.addSubview(blurView)
        blurView.fillSuperView(UIEdgeInsetsZero)
    }
    
    func setupTitle(title: String) {
        
        //TITLE
        titleLabel.setTranslatesAutoresizingMaskIntoConstraints(false)
        self.addSubview(titleLabel)
        
        let font = UIFont(name: "AppleSDGothicNeo-Bold", size: 25)!
        titleLabelHeight = UILabel.heightForLabel("asd", font: font, width: self.frame.width - (kTitlePadding * 2))
        
        titleLabel.addHeightConstraint(relation: .Equal, constant: titleLabelHeight)
        titleLabel.addLeftConstraint(toView: self, relation: .Equal, constant: kTitlePadding)
        titleLabel.addRightConstraint(toView: self, relation: .Equal, constant: -kTitlePadding)
        titleLabel.addBottomConstraint(toView: heroImageView, attribute: NSLayoutAttribute.Bottom, relation: .Equal, constant: -kTitlePadding)
        
        titleLabel.text = title
        titleLabel.font = font
        titleLabel.numberOfLines = 2
        titleLabel.lineBreakMode = NSLineBreakMode.ByWordWrapping
        titleLabel.textColor = UIColor.whiteColor()
        titleLabel.textAlignment = NSTextAlignment.Left
    }
}