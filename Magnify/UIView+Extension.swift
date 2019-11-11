//
//  UIView+Extension.swift
//  Sluice
//
//  Created by Khuong Huynh on 7/30/17.
//  Copyright © 2017 InMotion Software. All rights reserved.
//

import UIKit

protocol ActivityIndicatorProxy {
    func show() -> Self
    func hide()
}

//
// Nib
//
extension UIView {
    
    class func fromNib<T : UIView>() -> T {
        return Bundle.main.loadNibNamed(String(describing: T.self), owner: nil, options: nil)![0] as! T
    }

    static func instantiateFromNib() -> Self? {
        func instanceFromNib<T: UIView>() -> T? {
            return UINib(nibName: "\(self)", bundle: nil).instantiate(withOwner: nil, options: nil).first as? T
        }
        
        return instanceFromNib()
    }
}

//
// First Responder
//
extension UIView {
    var findFirstResponder: UIView? {
        
        var firstResponder: UIView?
 
        if self.isFirstResponder {
            firstResponder = self
        } else {
            for subview in self.subviews {
                if firstResponder == nil {
                    firstResponder = subview.findFirstResponder
                }
            }
        }

        return firstResponder
    }
}

//
// Utils
//
extension UIView {
    
    private static let activityIndicatorViewTag = -100
    
    private class UIViewActivityIndicatorProxy : ActivityIndicatorProxy {
        private weak var activityIndicatorView: UIActivityIndicatorView?
        
        init(view: UIView) {
            guard let backgroundView = view.subviews.first(where: {$0.tag == UIView.activityIndicatorViewTag} ) else {
                assertionFailure("View does not contain UIActivityIndicatorView")
                return
            }
            self.activityIndicatorView =
                backgroundView.subviews.first(where: { ($0 as? UIActivityIndicatorView) != nil} ) as? UIActivityIndicatorView
        }
        
        init(activityIndicatorView view: UIActivityIndicatorView) {
            self.activityIndicatorView = view
        }
        
        func show() -> Self {
            // show our parent 'background' view
            self.activityIndicatorView?.superview?.isHidden = false
            self.activityIndicatorView?.startAnimating()
            return self
        }
        
        func hide() {
            self.activityIndicatorView?.stopAnimating()
            
            // remove the backgroundView from superview
            self.activityIndicatorView?.superview?.removeFromSuperview()
            self.activityIndicatorView = nil
        }
    }
    
    func activityIndicator() -> ActivityIndicatorProxy {
        return self.showActivityIndicator(color: UIColor.green, backgroundColor: nil)
    }
    
    func activityIndicator (
        activityIndicatorStyle style: UIActivityIndicatorView.Style = .medium
        , color: UIColor?
        , backgroundColor: UIColor?
        , centerOffset: CGPoint = CGPoint(x: 0, y: 0)) -> ActivityIndicatorProxy {
        
        guard !self.subviews.contains(where: {$0.tag == UIView.activityIndicatorViewTag }) else {
            return UIViewActivityIndicatorProxy(view: self)
        }
        
        let frame = CGRect(x: 0.0, y: 0.0, width: 50.0, height: 50.0)
        let backgroundView = UIView(frame: frame)
        backgroundView.translatesAutoresizingMaskIntoConstraints = true
        backgroundView.center = CGPoint(x: self.bounds.midX + centerOffset.x, y: self.bounds.midY + centerOffset.y)
        backgroundView.autoresizingMask = [.flexibleLeftMargin
            , .flexibleRightMargin
            , .flexibleTopMargin
            , .flexibleBottomMargin]
        backgroundView.layer.cornerRadius = frame.width / 2.0
        backgroundView.backgroundColor = backgroundColor
        backgroundView.clipsToBounds = true
        backgroundView.tag = UIView.activityIndicatorViewTag
        self.addSubview(backgroundView)
        
        let activityIndicatorView = UIActivityIndicatorView(style: style)
        activityIndicatorView.center = CGPoint(x: frame.midX, y: frame.midY)
        
        if let color = color {
            activityIndicatorView.color = color
        }

        backgroundView.addSubview(activityIndicatorView)
        backgroundView.isHidden = true
        return UIViewActivityIndicatorProxy(activityIndicatorView: activityIndicatorView)
    }
    
    func showActivityIndicator() -> ActivityIndicatorProxy {
        return self.showActivityIndicator(color: UIColor.green, backgroundColor: nil)
    }
    
    func showActivityIndicator(
        activityIndicatorStyle style: UIActivityIndicatorView.Style = .medium
        , color: UIColor?
        , backgroundColor: UIColor?
        , centerOffset offset: CGPoint = CGPoint(x: 0, y: 0)) -> ActivityIndicatorProxy {
        
        return self.activityIndicator(activityIndicatorStyle: style,
                                      color: color,
                                      backgroundColor: backgroundColor,
                                      centerOffset: offset).show()
    }
    
}

