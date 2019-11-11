//
//  UIViewController+Alert.swift
//  Sluice
//
//  Created by Prince Ugwuh on 2/6/17.
//  Copyright © 2017 InMotion Software. All rights reserved.
//

import UIKit
import PromiseKit

protocol UIViewControllerAlert {

    @discardableResult
    func showAlert(for error: Error) -> Promise<Void>

    @discardableResult
    func showAlert(title: String, message: String) -> Promise<Void>
    
    @discardableResult
    func showAlert(title: String?, message: String, actions: [String], preferredActionIndex: Int?) -> Promise<Int>

    @discardableResult
    func showAlertPrompt(title: String?, message: String, placeholder: String?, text: String?, actions: [String], preferredActionIndex: Int?) -> Promise<(Int, String)>

}

extension UIViewController: UIViewControllerAlert {

    @discardableResult
    func showAlert(for error: Error) -> Promise<Void> {
        let title: String
        var message: String
            title = "Error"
            message = "Something went wrong. Please try again."
        
        #if DEBUG
            message = "\(message)\n\nError: \(error.localizedDescription)"
        #endif

        return self.showAlert(title: title, message: message)
    }

    @discardableResult
    func showAlert(title: String, message: String) -> Promise<Void> {
        return self.showAlert(title: title, message: message, actions: ["OK"]).then { _ -> Promise<Void> in return Promise() }
    }

    @discardableResult
    func showAlert(title: String? = nil, message: String, actions: [String], preferredActionIndex: Int? = nil) -> Promise<Int> {
        return Promise { seal in
            let vc = UIAlertController(title: title, message: message, preferredStyle: .alert)
            actions.enumerated().forEach { idx, title in
                let action = UIAlertAction(title: title, style: .default) { _ in seal.fulfill(idx) }
                vc.addAction(action)

                if (preferredActionIndex != nil && preferredActionIndex! == idx)
                    || idx == 0 {
                    vc.preferredAction = action
                }
            }
            
            if let popoverController = vc.popoverPresentationController {
                popoverController.sourceView = self.view
                popoverController.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.midY, width: 0, height: 0)
                popoverController.permittedArrowDirections = []
            }
            
            self.present(vc, animated: true, completion: nil)
        }
    }
    
    @discardableResult
    func showDeleteAlert(title: String? = nil, message: String) -> Promise<Int> {
        return Promise { seal in
            let vc = UIAlertController(title: title, message: message, preferredStyle: .actionSheet)
            vc.addAction(UIAlertAction(title: "Delete", style: .destructive) { _ in seal.fulfill(0) })
            vc.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in seal.fulfill(1) })
            vc.preferredAction = vc.actions[1]
            
            
            if let popoverController = vc.popoverPresentationController {
                popoverController.sourceView = self.view
                popoverController.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.midY, width: 0, height: 0)
                popoverController.permittedArrowDirections = []
            }
            
            self.present(vc, animated: true, completion: nil)
        }
    }

    @discardableResult
    func showAlertPrompt(title: String? = nil
                        , message: String
                        , placeholder: String? = nil
                        , text: String? = nil
                        , actions: [String]
                        , preferredActionIndex: Int? = nil) -> Promise<(Int, String)> {

        return Promise { seal in
            let vc = UIAlertController(title: title, message: message, preferredStyle: .alert)

            var textField: UITextField?
            if let placeholder = placeholder {
                vc.addTextField { tf in
                    tf.autocapitalizationType = .sentences
                    tf.placeholder = placeholder
                    tf.text = text
                    textField = tf
                }
            }

            actions.enumerated().forEach { idx, title in
                let action = UIAlertAction(title: title, style: .default) { _ in seal.fulfill((idx, textField?.text ?? "")) }
                vc.addAction(action)
                
                if (preferredActionIndex != nil && preferredActionIndex! == idx)
                    || idx == 0 {
                    vc.preferredAction = action
                }
            }
            
            if let popoverController = vc.popoverPresentationController {
                popoverController.sourceView = self.view
                popoverController.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.midY, width: 0, height: 0)
                popoverController.permittedArrowDirections = []
            }
            
            self.present(vc, animated: true, completion: nil)
        }
    }
}

protocol UIViewControllerActivityIndicator {
    func showActivityIndicator() -> ActivityIndicatorProxy
}

extension UIViewController: UIViewControllerActivityIndicator {

    func activityIndicator() -> ActivityIndicatorProxy {
        return self.view.activityIndicator(color: nil, backgroundColor: UIColor.green.withAlphaComponent(0.60))
    }

    func showActivityIndicator() -> ActivityIndicatorProxy {
        return self.activityIndicator().show();
    }
}
