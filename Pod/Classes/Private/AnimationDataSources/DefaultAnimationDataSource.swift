//
// Created by Nickolay Sheika on 6/8/16.
//

import Foundation
import UIKit

func * (lhs: CGPoint, rhs: CGFloat) -> CGPoint {
    return CGPoint(x: lhs.x * rhs, y: lhs.y * rhs)
}

func + (lhs: CGPoint, rhs: CGPoint) -> CGPoint {
    return CGPoint(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
}

func - (lhs: CGPoint, rhs: CGPoint) -> CGPoint {
    return lhs + rhs * -1.0
}

func limit(_ value: CGFloat, max maximum: CGFloat, min minimum: CGFloat) -> CGFloat {
    return min(max(value, minimum), maximum)
}

class DefaultAnimationDataSource: AnimationDataSource {

    // MARK: - Variables

    let animationCalculator: ImageAnimationCalculatorProtocol
    var proportionalFocusRect: CGRect?

    // MARK: - Init

    init(animationCalculator: ImageAnimationCalculatorProtocol) {
        self.animationCalculator = animationCalculator
    }

    convenience init(animationDependencies: ImageAnimationDependencies) {
        self.init(animationCalculator: ImageAnimationCalculator(animationDependencies: animationDependencies))
    }

    // MARK: - Public

    func buildAnimation(forImage: UIImage, forViewPortSize viewPortSize: CGSize) -> ImageAnimation {
        
        let image = forImage
        let imageSize = image.size
        
        if let proportionalFocusRect = proportionalFocusRect, proportionalFocusRect.size.width * proportionalFocusRect.size.height != 0.0 {
            
            let widthScale = viewPortSize.width / imageSize.width
            let heightScale = viewPortSize.height / imageSize.height
            let scaleForAspectFill = max(heightScale, widthScale)
            
            var scaledImageSize = imageSize.scaled(scaleForAspectFill)
            
            let xFocusScale = viewPortSize.width / (scaledImageSize.width * proportionalFocusRect.size.width)
            let yFocusScale = viewPortSize.height / (scaledImageSize.height * proportionalFocusRect.size.height)
            
            let focusScale = max(xFocusScale, yFocusScale, 1.0)
            
            let startScale = scaleForAspectFill * focusScale
            
            scaledImageSize = imageSize.scaled(startScale)
            
            
            let imageXDeviation = scaledImageSize.width / 2 - viewPortSize.width / 2
            let imageYDeviation = scaledImageSize.height / 2 - viewPortSize.height / 2
            let defaultOffset = CGPoint(x: imageXDeviation, y: imageYDeviation)
            
            var focusOffset = CGPoint(x: proportionalFocusRect.origin.x * scaledImageSize.width - (viewPortSize.width - scaledImageSize.width * proportionalFocusRect.size.width) / 2,
                                      y: proportionalFocusRect.origin.y * scaledImageSize.height - (viewPortSize.height - scaledImageSize.height * proportionalFocusRect.size.height) / 2)
            
            let maxXOffset = 2 * imageXDeviation
            let maxYOffset = 2 * imageYDeviation
            let minOffset: CGFloat = 0.0
            
            focusOffset.x = limit(focusOffset.x, max: maxXOffset, min: minOffset)
            focusOffset.y = limit(focusOffset.y, max: maxYOffset, min: minOffset)
            
            let startImagePosition = focusOffset - defaultOffset
            let endImagePosition = CGPoint(x: maxXOffset, y: maxYOffset) - focusOffset - defaultOffset
            
            let duration = animationCalculator.buildAnimationDuration()
            let imageStart = ImageState(scale: startScale + 0.1, position: startImagePosition)
            let imageEnd = ImageState(scale: startScale, position: endImagePosition)
            let imageAnimation = ImageAnimation(startState: imageStart, endState: imageEnd, duration: duration)
            
            return imageAnimation
        }
        
        // ...or go with silly random stuff

        let startScale = animationCalculator.buildRandomScale(imageSize: imageSize, viewPortSize: viewPortSize)
        let endScale = animationCalculator.buildRandomScale(imageSize: imageSize, viewPortSize: viewPortSize)

        let scaledStartImageSize = imageSize.scaled(startScale)
        let scaledEndImageSize = imageSize.scaled(endScale)

        let imageStartPosition = animationCalculator.buildPinnedToEdgesPosition(imageSize: scaledStartImageSize,
                                                                                viewPortSize: viewPortSize)
        let imageEndPosition = animationCalculator.buildOppositeAnglePosition(startPosition: imageStartPosition,
                                                                              imageSize: scaledEndImageSize,
                                                                              viewPortSize: viewPortSize)

        let duration = animationCalculator.buildAnimationDuration()

        let imageStartState = ImageState(scale: startScale, position: imageStartPosition)
        let imageEndState = ImageState(scale: endScale, position: imageEndPosition)
        let imageTransition = ImageAnimation(startState: imageStartState, endState: imageEndState, duration: duration)

        return imageTransition
    }

    // MARK: - Private

    private func translateToImageCoordinates(point point: CGPoint, imageSize: CGSize, viewPortSize: CGSize) -> CGPoint {
        let x = imageSize.width / 2 - viewPortSize.width / 2 - point.x
        let y = imageSize.height / 2 - viewPortSize.height / 2 - point.y
        let position = CGPoint(x: x, y: y)
        return position
    }
}
