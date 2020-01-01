//
//  OnboardingViewController.swift
//  Magnify
//
//  Created by Thomas Nelson on 12/29/19.
//  Copyright © 2019 TKO Solutions. All rights reserved.
//

import UIKit

class OnboardingViewController: UIViewController {

    public enum OnboardingData {
        case page0
        case page1
        case page2
        case page3
        case page4
        case page5
        case page6
        case page7

        var count: Int {
            return 8
        }
        
        var index: Int {
            switch self {
                case .page0: return 0
                case .page1: return 1
                case .page2: return 2
                case .page3: return 3
                case .page4: return 4
                case .page5: return 5
                case .page6: return 6
                case .page7: return 7
            }
        }
        
        var next: OnboardingData? {
            switch self {
                case .page0: return .page1
                case .page1: return .page2
                case .page2: return .page3
                case .page3: return .page4
                case .page4: return .page5
                case .page5: return .page6
                case .page6: return .page7
                case .page7: return nil
            }
        }
        
        var previous: OnboardingData? {
            switch self {
                case .page0: return nil
                case .page1: return .page0
                case .page2: return .page1
                case .page3: return .page2
                case .page4: return .page3
                case .page5: return .page4
                case .page6: return .page5
                case .page7: return .page6
            }
        }

        var title: String {
            switch self {
                case .page0: return "Welcome"
                case .page1: return "Tap"
                case .page2: return "Light"
                case .page3: return "Camera Zoom"
                case .page4: return "Reset"
                case .page5: return "Picture Zoom"
                case .page6: return "Pan"
                case .page7: return "Clear"
            }
        }
        
        var detail: String {
            switch self {
                case .page0: return "E-Z Reader lets you grab snapshots of hard to read text for when you forgot your \"Readers\""
                case .page1: return "Tap on the screen to capture a picture. These will be temporary only, they are not saved to your camera roll"
                case .page2: return "Swipe right to turn on the camera light. Keep swiping to raise the intensity. The Light indicator at the top shows the status of the light intensity."
                case .page3: return "Use two fingers to zoom the camera. The camera can be zoomed up to 10X and the current zoom is shown in the display."
                case .page4: return "You can quickly reset the zoom to 1.0 and turn off the light by pressing the reset button. It is enabled if there is any zoom or light enabled."
                case .page5: return "After you tap and take a picture, you can zoom the picture to get a larger view of anything of interest. "
                case .page6: return "After zooming the picture, you can pan it in any direction."
                case .page7: return "After you are done with the picture, press Clear to go back to the camera to take another picture."
            }
        }
        
        var image: UIImage? {
            switch self {
                case .page0: return UIImage(named: "onboarding-page-one")
                case .page1: return UIImage(named: "onboarding-page-one")
                case .page2: return UIImage(named: "onboarding-page-two")
                case .page3: return UIImage(named: "onboarding-page-three")
                case .page4: return UIImage(named: "onboarding-page-three")
                case .page5: return UIImage(named: "onboarding-page-three")
                case .page6: return UIImage(named: "onboarding-page-three")
                case .page7: return UIImage(named: "onboarding-page-three")
            }
        }
    }
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var detailLabel: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    
    
    var page: OnboardingData = .page0

    override func viewDidLoad() {
        super.viewDidLoad()
        self.titleLabel.text = page.title
        self.detailLabel.text = page.detail
        self.imageView.image = page.image
    }

    class func instantiate(_ page: OnboardingData = .page0) -> OnboardingViewController {
        let onboardingViewController: OnboardingViewController = OnboardingViewController.storyboard("Onboarding")
        onboardingViewController.page = page

        return onboardingViewController
    }
}
