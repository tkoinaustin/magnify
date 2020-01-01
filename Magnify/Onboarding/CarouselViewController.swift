//
//  CarouselViewController.swift
//  Magnify
//
//  Created by Thomas Nelson on 12/28/19.
//  Copyright © 2019 TKO Solutions. All rights reserved.
//

import UIKit

enum CarouselResponse {
    case carouselComplete
}

class CarouselViewController: UIViewController {

    @IBOutlet private weak var contentView: UIView!
    @IBOutlet private weak var previousButton: UIButton!
    @IBOutlet private weak var nextButton: UIButton!
    @IBOutlet private weak var doneButton: UIButton!
    
    private let pageViewController = UIPageViewController.init(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil)
    
    class func instantiate() -> CarouselViewController {
        return CarouselViewController.storyboard("Onboarding")
    }

    @IBAction private func previousAction(_ sender: UIButton) {
        guard let onboardingViewController = self.pageViewController.viewControllers?[0] as? OnboardingViewController else { return }
        guard let previousViewController = self.nextViewController(onboardingViewController, direction: .reverse) else { return }
        self.pageViewController.setViewControllers([previousViewController], direction: .reverse , animated: true)
        UIView.animate(withDuration: 0.5) {
            self.previousButton.alpha = previousViewController.page.index == 0 ? 0 : 1
        }
        self.nextButton.setTitle("NEXT", for: .normal)
    }
    
    @IBAction private func nextAction(_ sender: UIButton) {
        guard let onboardingViewController = self.pageViewController.viewControllers?[0] as? OnboardingViewController else { return }
        guard let forwardViewController = self.nextViewController(onboardingViewController, direction: .forward) else {
            self.done()
            return
        }
        self.pageViewController.setViewControllers([forwardViewController], direction: .forward , animated: true)
        UIView.animate(withDuration: 0.5) {
            self.previousButton.alpha = 1
        }
        let nextLabel = forwardViewController.page.count == forwardViewController.page.index + 1 ? "DONE" : "NEXT"
        self.nextButton.setTitle(nextLabel, for: .normal)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.setHidesBackButton(true, animated: true)
        self.navigationController?.setNavigationBarHidden(true, animated: true)
        self.configure()
    }
    
    private func configure() {
        self.pageViewController.delegate = self
        self.pageViewController.dataSource = self
        let pageAppearance = UIPageControl.appearance()
        pageAppearance.currentPageIndicatorTintColor = UIColor.init(red: 0, green: 0.5, blue: 1, alpha: 1)
        pageAppearance.pageIndicatorTintColor = UIColor.init(red: 0, green: 0.5, blue: 1, alpha: 0.25)

        self.addChild(self.pageViewController)
        self.pageViewController.didMove(toParent: self)
        self.previousButton.alpha = 0

        self.pageViewController.view.translatesAutoresizingMaskIntoConstraints = false
        self.contentView.insertSubview(self.pageViewController.view, at: 0)
        
        self.contentView.leadingAnchor.constraint(equalTo: self.pageViewController.view.leadingAnchor, constant: 0).isActive = true
        self.contentView.trailingAnchor.constraint(equalTo: self.pageViewController.view.trailingAnchor, constant: 0).isActive = true
        self.contentView.topAnchor.constraint(equalTo: self.pageViewController.view.topAnchor, constant: 0).isActive = true
        self.contentView.bottomAnchor.constraint(equalTo: self.pageViewController.view.bottomAnchor, constant: 0).isActive = true
        
        let startingViewController = OnboardingViewController.instantiate(.page0)
        self.pageViewController.setViewControllers([startingViewController], direction: .forward, animated: true)
    }

    private func nextViewController(_ currentViewController: OnboardingViewController,
                                      direction: UIPageViewController.NavigationDirection) -> OnboardingViewController? {
        switch direction {
            case .forward: ()
                if let nextPage = currentViewController.page.next { return OnboardingViewController.instantiate(nextPage)}
            case .reverse: ()
                if let previousPage = currentViewController.page.previous { return OnboardingViewController.instantiate(previousPage)}
        }
        return nil
    }
    
    private func done() {
        self.performSegue(withIdentifier: "cameraSegue", sender: nil)
    }
}

extension CarouselViewController: UIPageViewControllerDelegate, UIPageViewControllerDataSource {
    
    func presentationIndex(for pageViewController: UIPageViewController) -> Int {
        guard let onboardingViewController = pageViewController.viewControllers?[0] as? OnboardingViewController else { return 0 }
        return onboardingViewController.page.index
    }
    
    func presentationCount(for pageViewController: UIPageViewController) -> Int {
        guard let onboardingViewController = pageViewController.viewControllers?[0] as? OnboardingViewController else { return 1 }
        return onboardingViewController.page.count
    }

    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        if let previousPage = (viewController as? OnboardingViewController)?.page.previous { return OnboardingViewController.instantiate(previousPage)
        } else {
            return nil
        }
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        if let nextPage = (viewController as? OnboardingViewController)?.page.next {
            return OnboardingViewController.instantiate(nextPage)
        } else {
            return nil
        }
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, willTransitionTo pendingViewControllers: [UIViewController]) {
        guard let onboardingViewController = (pendingViewControllers[0] as? OnboardingViewController) else { return }
        UIView.animate(withDuration: 0.5) {
            self.previousButton.alpha = onboardingViewController.page.index == 0 ? 0 : 1
        }
        let nextLabel = onboardingViewController.page.count == onboardingViewController.page.index + 1 ? "DONE" : "NEXT"
        self.nextButton.setTitle(nextLabel, for: .normal)
    }
}
