//
//  UITableViewCell+Extension.swift
//  Sluice
//
//  Created by Prince Ugwuh on 6/13/16.
//  Copyright © 2016 InMotion Software. All rights reserved.
//


import UIKit

extension UIStoryboard {
    class func makeViewController<T: Identifiable>(fromStoryboard name: String = "Main") -> T? {
        let storyboard: UIStoryboard = UIStoryboard(name: name, bundle: nil)
        return storyboard.instantiateViewController(withIdentifier: T.identifier) as? T
    }
    
    class func makeInitialViewController<T: Identifiable>(fromStoryboard name: String = "Main") -> T? {
        let storyboard: UIStoryboard = UIStoryboard(name: name, bundle: nil)
        return storyboard.instantiateInitialViewController() as? T
    }

}
