//
//  Identifier.swift
//  Sluice
//
//  Created by Prince Ugwuh on 2/13/17.
//  Copyright © 2017 InMotion Software. All rights reserved.
//

import UIKit

protocol Identifiable {
    var identifier: String { get }
    static var identifier: String { get }
}

extension Identifiable {
    var identifier: String {
        return String(describing: self)
    }
    
    static var identifier: String {
        return String(describing: self)
    }
}

extension Identifiable where Self: NSObjectProtocol {
    var identifier: String {
        return String(describing: type(of: self))
    }
}

extension UIViewController: Identifiable {}
extension UITableViewCell: Identifiable {}
extension UICollectionViewCell: Identifiable {}
