//
// Created by Nickolay Sheika on 4/25/16.
//

import Foundation
import UIKit
import QuartzCore

extension CGFloat {
    static var phi: CGFloat {
        return (1 + sqrt(5)) / 2
    }
}

@objc public protocol APKenBurnsViewDataSource {
    /*
     Main data source method. Data source should provide next image.
     If no image provided (data source returns nil) then previous image will be used one more time.
     */
    func nextImage(forKenBurnsView: APKenBurnsView) -> UIImage?
}


@objc public protocol APKenBurnsViewDelegate {
    
    /*
     Called when transition starts from one image to another
     */
    @objc optional func didStartTransition(forKenBurnsView: APKenBurnsView, toImage: UIImage)
    
    /*
     Called when transition from one image to another is paused
     */
    @objc optional func didPauseTransition(forKenBurnsView: APKenBurnsView)
    
    /*
     Called when transition from one image to another is resumed
     */
    @objc optional func didResumeTransition(forKenBurnsView: APKenBurnsView)
    
    /*
     Called when transition from one image to another is finished
     */
    @objc optional func didFinishTransition(forKenBurnsView: APKenBurnsView)
}


public enum APKenBurnsViewFaceRecognitionMode {
    case none         // no face recognition, simple Ken Burns effect
    case biggest      // recognizes biggest face in image, if any then transition will start or will finish (chosen randomly) in center of face rect.
    case group        // recognizes all faces in image, if any then transition will start or will finish (chosen randomly) in center of compound rect of all faces.
}


public class APKenBurnsView: UIView {
    
    // MARK: - DataSource
    
    /*
     NOTE: Interface Builder does not support connecting to an outlet in a Swift file when the outlet’s type is a protocol.
     Workaround: Declare the outlet's type as AnyObject or NSObject, connect objects to the outlet using Interface Builder, then change the outlet's type back to the protocol.
     */
    @IBOutlet public weak var dataSource: APKenBurnsViewDataSource?
    
    
    // MARK: - Delegate
    
    /*
     NOTE: Interface Builder does not support connecting to an outlet in a Swift file when the outlet’s type is a protocol.
     Workaround: Declare the outlet's type as AnyObject or NSObject, connect objects to the outlet using Interface Builder, then change the outlet's type back to the protocol.
     */
    @IBOutlet public weak var delegate: APKenBurnsViewDelegate?
    
    
    // MARK: - Animation Setup
    
    /*
     Face recognition mode. See APKenBurnsViewFaceRecognitionMode docs for more information.
     */
    public var faceRecognitionMode: APKenBurnsViewFaceRecognitionMode = .none
    
    /*
     Allowed deviation of scale factor.
     
     Example: If scaleFactorDeviation = 0.5 then allowed scale will be from 1.0 to 1.5.
     If scaleFactorDeviation = 0.0 then allowed scale will be from 1.0 to 1.0 - fixed scale factor.
     */
    @IBInspectable public var scaleFactorDeviation: Float = 1.0
    
    /*
     Animation duration of one image
     */
    @IBInspectable public var imageAnimationDuration: Double = 10.0
    
    /*
     Allowed deviation of animation duration of one image
     
     Example: if imageAnimationDuration = 10 seconds and imageAnimationDurationDeviation = 2 seconds then
     resulting image animation duration will be from 8 to 12 seconds
     */
    @IBInspectable public var imageAnimationDurationDeviation: Double = 0.0
    
    /*
     Duration of transition animation between images
     */
    @IBInspectable public var transitionAnimationDuration: Double = 4.0
    
    /*
     Allowed deviation of animation duration of one image
     */
    @IBInspectable public var transitionAnimationDurationDeviation: Double = 0.0
    
    /*
     If set to true then recognized faces will be shown as rectangles. Only applicable for debugging.
     */
    @IBInspectable public var showFaceRectangles: Bool = false
    
    /*
     If set to true, nextImage requests to datasource are periodically repeated when it returned nil.
     During this process, an activity indicator is shown.
     */
    @IBInspectable public var repeatsNextImageRequests: Bool = false
    
    
    // MARK: - Init
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    
    // MARK: - Public
    
    public func startAnimations() {
        stopAnimations()
        
        animationDataSource = buildAnimationDataSource()
        
        firstImageView.alpha = 1.0
        secondImageView.alpha = 0.0
        
        loadingView.isHidden = true
        
        stopWatch = StopWatch()
        
        requestNewImageForTransition(imageView: firstImageView, nextImageView: secondImageView)
    }
    
    public func pauseAnimations() {
        if !(timer?.isPaused ?? true) {
            self.delegate?.didPauseTransition?(forKenBurnsView: self)
            
            firstImageView.backupAnimations()
            secondImageView.backupAnimations()
            
            timer?.pause()
            layer.pauseAnimations()
        }
    }
    
    public func resumeAnimations() {
        if timer?.isPaused ?? false {
            self.delegate?.didResumeTransition?(forKenBurnsView: self)
            
            firstImageView.restoreAnimations()
            secondImageView.restoreAnimations()
            
            timer?.resume()
            layer.resumeAnimations()
        }
    }
    
    public func stopAnimations() {
        timer?.cancel()
        layer.removeAllAnimations()
    }
    
    
    // MARK: - Private Variables
    
    private var firstImageView: UIImageView!
    private var secondImageView: UIImageView!
    private var loadingView: UIView!
    
    private var animationDataSource: AnimationDataSource!
    private var facesDrawer: FacesDrawerProtocol!
    
    private let notificationCenter = NotificationCenter.default
    
    private var timer: BlockTimer?
    private var stopWatch: StopWatch!
    
    
    // MARK: - Setup
    
    private func setup() {
        firstImageView = buildDefaultImageView()
        secondImageView = buildDefaultImageView()
        loadingView = buildLoadingView()
        facesDrawer = FacesDrawer()
    }
    
    
    // MARK: - Lifecycle
    
    public override func didMoveToSuperview() {
        guard superview == nil else {
            notificationCenter.addObserver(self,
                                           selector: #selector(applicationWillResignActive),
                                           name: .UIApplicationWillResignActive,
                                           object: nil)
            notificationCenter.addObserver(self,
                                           selector: #selector(applicationDidBecomeActive),
                                           name: .UIApplicationDidBecomeActive,
                                           object: nil)
            return
        }
        notificationCenter.removeObserver(self)
        
        // required to break timer retain cycle
        stopAnimations()
    }
    
    deinit {
        notificationCenter.removeObserver(self)
    }
    
    
    // MARK: - Notifications
    
    @objc private func applicationWillResignActive(notification: NSNotification) {
        pauseAnimations()
    }
    
    @objc private func applicationDidBecomeActive(notification: NSNotification) {
        resumeAnimations()
    }
    
    
    // MARK: - Timer
    
    private func startTimerWithDelay(delay: Double, callback: @escaping () -> ()) {
        stopTimer()
        
        timer = BlockTimer(interval: delay, callback: callback)
    }
    
    private func stopTimer() {
        timer?.cancel()
    }
    
    
    // MARK: - Private
    
    private func buildAnimationDataSource() -> AnimationDataSource {
        let animationDependencies = ImageAnimationDependencies(scaleFactorDeviation: scaleFactorDeviation,
                                                               imageAnimationDuration: imageAnimationDuration,
                                                               imageAnimationDurationDeviation: imageAnimationDurationDeviation)
        let animationDataSourceFactory = AnimationDataSourceFactory(animationDependencies: animationDependencies,
                                                                    faceRecognitionMode: faceRecognitionMode)
        return animationDataSourceFactory.buildAnimationDataSource()
    }
    
    private func requestNewImageForTransition(imageView: UIImageView, nextImageView: UIImageView) {
        if let image = self.dataSource?.nextImage(forKenBurnsView: self) {
            loadingView.isHidden = true
            self.startTransitionWithImage(image: image, imageView: imageView, nextImageView: nextImageView)
        } else {
            if repeatsNextImageRequests {
                loadingView.isHidden = false
                self.bringSubview(toFront: loadingView)
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.1) {
                    self.requestNewImageForTransition(imageView: imageView, nextImageView: nextImageView)
                }
            } else {
                self.startTransitionWithImage(image: nextImageView.image ?? UIImage(), imageView: imageView, nextImageView: nextImageView)
            }
        }
    }
    
    private func startTransitionWithImage(image: UIImage, imageView: UIImageView, nextImageView: UIImageView) {
        guard isValidAnimationDurations() else {
            fatalError("Animation durations setup is invalid!")
        }
        
        DispatchQueue.global().async {
            self.stopWatch.start()
            
            var animation = self.animationDataSource.buildAnimation(forImage: image, forViewPortSize: self.bounds.size)
            
            DispatchQueue.main.async {
                
                let animationTimeCompensation = self.stopWatch.duration
                animation = ImageAnimation(startState: animation.startState,
                                           endState: animation.endState,
                                           duration: animation.duration - animationTimeCompensation)
                
                imageView.image = image
                imageView.animateWithImageAnimation(animation: animation)
                
                if self.showFaceRectangles {
                    self.facesDrawer.drawFacesInView(view: imageView, image: image)
                }
                
                let duration = self.buildAnimationDuration()
                let delay = animation.duration - duration / 2
                
                self.startTimerWithDelay(delay: delay) {
                    
                    self.delegate?.didStartTransition?(forKenBurnsView: self, toImage: image)
                    
                    self.animateTransitionWithDuration(duration: duration, imageView: imageView, nextImageView: nextImageView) {
                        self.delegate?.didFinishTransition?(forKenBurnsView: self)
                        self.facesDrawer.cleanUpForView(view: imageView)
                    }
                    
                    self.requestNewImageForTransition(imageView: nextImageView, nextImageView: imageView)
                }
            }
        }
    }
    
    private func animateTransitionWithDuration(duration: Double, imageView: UIImageView, nextImageView: UIImageView, completion: @escaping () -> ()) {
        UIView.animate(withDuration: duration,
                       delay: 0.0,
                       options: .curveEaseInOut,
                       animations: {
                        imageView.alpha = 0.0
                        nextImageView.alpha = 1.0 },
                       completion: { finished in
                        completion() })
    }
    
    private func buildAnimationDuration() -> Double {
        var durationDeviation = 0.0
        if transitionAnimationDurationDeviation > 0.0 {
            durationDeviation = RandomGenerator().randomDouble(min: -transitionAnimationDurationDeviation,
                                                               max: transitionAnimationDurationDeviation)
        }
        let duration = transitionAnimationDuration + durationDeviation
        return duration
    }
    
    private func isValidAnimationDurations() -> Bool {
        return imageAnimationDuration - imageAnimationDurationDeviation -
            (transitionAnimationDuration - transitionAnimationDurationDeviation) / 2 > 0.0
    }
    
    private func buildDefaultImageView() -> UIImageView {
        let imageView = UIImageView(frame: bounds)
        imageView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        imageView.contentMode = .center
        addSubview(imageView)
        
        return imageView
    }
    
    private func buildLoadingView() -> UIView {
        let view = UIView(frame: bounds)
        view.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        view.contentMode = .center
        view.backgroundColor = UIColor.darkGray
        addSubview(view)
        
        let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .whiteLarge)
        activityIndicator.frame.origin = CGPoint(x: (view.frame.size.width - activityIndicator.frame.size.width) / 2, y: UIScreen.main.bounds.width / CGFloat.phi - activityIndicator.frame.size.width / 2)
        activityIndicator.autoresizingMask = [.flexibleLeftMargin, .flexibleRightMargin]
        activityIndicator.startAnimating()
        view.addSubview(activityIndicator)
        
        return view
    }
}
