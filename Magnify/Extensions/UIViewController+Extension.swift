//
//  UIViewController+Extension.swift
//  Sluice
//
//  Created by Prince Ugwuh on 3/21/17.
//  Copyright © 2017 InMotion Software. All rights reserved.
//

import UIKit
import PromiseKit

//
// MARK: Storyboard
//

extension UIViewController {

    class func storyboard<T: UIViewController>(_ name: String) -> T {
        return UIStoryboard.makeViewController(fromStoryboard: name)!
    }
}
