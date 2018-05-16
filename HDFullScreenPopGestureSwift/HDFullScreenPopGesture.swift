//
//  HDFullScreenPopGesture.swift
//  HDFullScreenPopGestureSwift
//
//  Created by HD-XXZQ-iMac on 2018/5/16.
//  Copyright © 2018年 HD-XXZQ-iMac. All rights reserved.
//


import UIKit

typealias HDVCWillAppearInjectBlock = (_ vc: UIViewController?, _ animated: Bool) -> Void

extension  UIViewController {
    
    // MARK:- RuntimeKey   动态绑属性
    struct RuntimeKey {
        static let hd_popDisabled = UnsafeRawPointer.init(bitPattern: "hd_popDisabled".hashValue)
        static let hd_navigationBarHidden = UnsafeRawPointer.init(bitPattern: "hd_navigationBarHidden".hashValue)
        static let hd_allowPopDistance = UnsafeRawPointer.init(bitPattern: "hd_allowPopDistance".hashValue)
        static let hd_fullScreenPopGestureRecognizer = UnsafeRawPointer.init(bitPattern: "hd_fullScreenPopGestureRecognizer".hashValue)
        static let hd_willAppearInjectBlock = UnsafeRawPointer.init(bitPattern: "hd_willAppearInjectBlock".hashValue)
        static let hd_popGestureRecognizerDelegate = UnsafeRawPointer.init(bitPattern: "hd_popGestureRecognizerDelegate".hashValue)
    }
    
    // MARK:- 是否开启侧滑，默认true
   public var hd_popDisabled: Bool? {
        set {
            objc_setAssociatedObject(self, RuntimeKey.hd_popDisabled!, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        get {
            return objc_getAssociatedObject(self, RuntimeKey.hd_popDisabled!) as? Bool
        }
    }
    
    // MARK:- 是否隐藏导航栏，默认false
    public var hd_navigationBarHidden: Bool? {
        set {
            objc_setAssociatedObject(self, RuntimeKey.hd_navigationBarHidden!, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        get {
            return objc_getAssociatedObject(self, RuntimeKey.hd_navigationBarHidden!) as? Bool
        }
    }
    
    // MARK:- 允许侧滑的手势范围。默认全屏
   public var hd_allowPopDistance: CGFloat? {
        set {
            objc_setAssociatedObject(self, RuntimeKey.hd_allowPopDistance!, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        get {
            return objc_getAssociatedObject(self, RuntimeKey.hd_allowPopDistance!) as? CGFloat
        }
    }
    
  fileprivate  var hd_willAppearInjectBlock:HDVCWillAppearInjectBlock? {
        set {
            objc_setAssociatedObject(self, RuntimeKey.hd_willAppearInjectBlock!, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        get {
            return objc_getAssociatedObject(self, RuntimeKey.hd_willAppearInjectBlock!) as? HDVCWillAppearInjectBlock
        }
    }
    
}

// MARK:UIViewController  交换viewWillAppear(_:)与viewWillDisappear(_:)方法
extension UIViewController:SelfAware {
    static func awake() {
        UIViewController.classInit()
        UINavigationController.classInitial()
    }

    static func classInit() {
        swizzleMethod
    }

    @objc fileprivate func swizzled_viewWillAppear(_ animated: Bool) {
        swizzled_viewWillAppear(animated)
        if self.hd_willAppearInjectBlock != nil {
            self.hd_willAppearInjectBlock!(self,animated)
        }
    }
    
    @objc  func swizzled_viewWillDisAppear(_ animated: Bool) {
        swizzled_viewWillDisAppear(animated)
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now()) {
            let viewcontroller = self.navigationController?.viewControllers.last
            if (viewcontroller != nil && viewcontroller?.hd_navigationBarHidden == nil) {
                self.navigationController?.setNavigationBarHidden(false, animated: false);
            }
        }
    }
    
    private static let swizzleMethod: Void = {
        let originalSelector = #selector(viewWillAppear(_:))
        let swizzledSelector = #selector(swizzled_viewWillAppear(_:))
        swizzlingForClass(UIViewController.self, originalSelector: originalSelector, swizzledSelector: swizzledSelector)
        
        let originalSelector1 = #selector(viewWillDisappear(_:))
        let swizzledSelector1 = #selector(swizzled_viewWillDisAppear(_:))
        swizzlingForClass(UIViewController.self, originalSelector: originalSelector1, swizzledSelector: swizzledSelector1)
    }()
    
     static func swizzlingForClass(_ forClass: AnyClass, originalSelector: Selector, swizzledSelector: Selector) {
        let originalMethod = class_getInstanceMethod(forClass, originalSelector)
        let swizzledMethod = class_getInstanceMethod(forClass, swizzledSelector)
        guard (originalMethod != nil && swizzledMethod != nil) else {
            return
        }
        if class_addMethod(forClass, originalSelector, method_getImplementation(swizzledMethod!), method_getTypeEncoding(swizzledMethod!)) {
            class_replaceMethod(forClass, swizzledSelector, method_getImplementation(originalMethod!), method_getTypeEncoding(originalMethod!))
        } else {
            method_exchangeImplementations(originalMethod!, swizzledMethod!)
        }
    }
}

// MARK:UINavigationController  交换pushViewController(_:animated:)方法
extension UINavigationController {
    static func classInitial() {
        swizzleMethod
    }
    
    private static let swizzleMethod: Void = {
        let originalSelector = #selector(UINavigationController.pushViewController(_:animated:))
        let swizzledSelector = #selector(hd_pushViewController)
        swizzlingForClass(UINavigationController.self, originalSelector: originalSelector, swizzledSelector: swizzledSelector)
    }()

    @objc fileprivate func hd_pushViewController(_ viewController: UIViewController, animated: Bool) {
        guard let contains = self.interactivePopGestureRecognizer?.view?.gestureRecognizers?.contains(self.hd_fullScreenPopGestureRecognizer!) else { return }
        
        if !contains {
            guard let hd_fullScreenPopGestureRecognizer = self.hd_fullScreenPopGestureRecognizer else { return }
            guard let systemGesture = interactivePopGestureRecognizer else { return  }
            guard let gestureView = systemGesture.view else { return  }
            gestureView.addGestureRecognizer(hd_fullScreenPopGestureRecognizer)
            let targets = systemGesture.value(forKey: "targets") as! [NSObject]
            guard let targetObj = targets.first else { return }
            guard let target = targetObj.value(forKey: "target") else { return }
            let action = Selector(("handleNavigationTransition:"))
            hd_fullScreenPopGestureRecognizer.delegate = self.hd_popGestureRecognizerDelegate
            hd_fullScreenPopGestureRecognizer.addTarget(target, action: action)
            self.interactivePopGestureRecognizer?.isEnabled = false
        }
        
        self.hd_setupVCNavigationBarAppearanceIfNeeded(appearingVC: viewController)
        if !(self.viewControllers.contains(viewController)) {
            self.hd_pushViewController(viewController, animated: animated)
        }
    }
    
   fileprivate func hd_setupVCNavigationBarAppearanceIfNeeded(appearingVC:UIViewController) {
        weak var weakSelf = self
        let block: HDVCWillAppearInjectBlock = {(_ vc: UIViewController?, _ animated: Bool) -> Void in
            let strongSelf = weakSelf
            if (strongSelf != nil) {
                strongSelf?.setNavigationBarHidden(vc?.hd_navigationBarHidden != nil, animated: animated)
            }
        }
        
        appearingVC.hd_willAppearInjectBlock = block
        guard let disAppearingVC = self.viewControllers.last else { return }
        if disAppearingVC.hd_willAppearInjectBlock == nil {
            disAppearingVC.hd_willAppearInjectBlock = block
        }
    }
    
   fileprivate var hd_popGestureRecognizerDelegate: HDFullScreenPopGestureRecognizerDelegate? {
        get {
            var delegate = objc_getAssociatedObject(self, RuntimeKey.hd_popGestureRecognizerDelegate!) as? HDFullScreenPopGestureRecognizerDelegate
            if delegate == nil {
                delegate = HDFullScreenPopGestureRecognizerDelegate()
                delegate?.navigationController = self
                objc_setAssociatedObject(self, RuntimeKey.hd_popGestureRecognizerDelegate!, delegate!, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            }
            return delegate!
        }
    }
    
   fileprivate var hd_fullScreenPopGestureRecognizer : UIPanGestureRecognizer? {
        get {
            var pan = objc_getAssociatedObject(self, RuntimeKey.hd_fullScreenPopGestureRecognizer!) as? UIPanGestureRecognizer
            if pan == nil {
                pan = UIPanGestureRecognizer()
                pan!.maximumNumberOfTouches = 1
                objc_setAssociatedObject(self, RuntimeKey.hd_fullScreenPopGestureRecognizer!, pan!, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            }
            return pan!
        }
    }
}

class HDFullScreenPopGestureRecognizerDelegate: NSObject, UIGestureRecognizerDelegate {
    weak var navigationController: UINavigationController?
    
    // 与OC不同的是，这里不能直接把UIGestureRecognizerDelegate写成是UIPanGestureRecognizer的，必须得是UIGestureRecognizer。
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
    
        let panGestureRecognizer = gestureRecognizer as! UIPanGestureRecognizer
        
        if (self.navigationController?.viewControllers.count)! <= 1 {
            return false
        }
        
        let topVC: UIViewController? = navigationController?.viewControllers.last
        if let disabled = topVC?.hd_popDisabled  {
            if disabled {
                return false
            }
        }
   
        let beginLocation: CGPoint = panGestureRecognizer.location(in: panGestureRecognizer.view)
        let allowedDistance: CGFloat? = topVC?.hd_allowPopDistance
        if (allowedDistance ?? 0.0) > 0 && beginLocation.x > (allowedDistance ?? 0.0) {
            return false
        }
        
        let isTransitioning = navigationController?.value(forKey: "_isTransitioning") as? Bool
        
        if let t = isTransitioning {
            if t {
                return false
            }
        }
        
        let translation: CGPoint = panGestureRecognizer.translation(in: panGestureRecognizer.view)
        let isLeftToRight: Bool = UIApplication.shared.userInterfaceLayoutDirection == .leftToRight
        let multiplier: CGFloat = isLeftToRight ? 1 : -1
        if (translation.x * multiplier) <= 0 {
            return false
        }

        return true
    }
}

// MARK:- SelfAware 定义协议，使得程序在初始化的时候，将遵循该协议的类做了方法交换
protocol SelfAware: class {
    static func awake()
}

class NothingToSeeHere {
    static func harmlessFunction() {
        let typeCount = Int(objc_getClassList(nil, 0))
        let types = UnsafeMutablePointer<AnyClass>.allocate(capacity: typeCount)
        let autoreleasingTypes = AutoreleasingUnsafeMutablePointer<AnyClass>(types)
        objc_getClassList(autoreleasingTypes, Int32(typeCount))
        for index in 0 ..< typeCount {
            (types[index] as? SelfAware.Type)?.awake()
        }
        //        types.deallocate(capacity: typeCount)
        types.deallocate()
    }
}

extension UIApplication {
    private static let runOnce: Void = {
        NothingToSeeHere.harmlessFunction()
    }()
    override open var next: UIResponder? {
        // Called before applicationDidFinishLaunching
        UIApplication.runOnce
        return super.next
    }
}
