//
// Created by Nickolay Sheika on 6/8/16.
//

import Foundation
import UIKit
import QuartzCore

enum FaceRecognitionMode {
    case biggest
    case group

    init(mode: APKenBurnsViewFaceRecognitionMode) {
        switch mode {
            case .none:
                fatalError("Unsupported mode!")
            case .biggest:
                self = .biggest
            case .group:
                self = .group
        }
    }
}


class FaceAnimationDataSource: AnimationDataSource {

    // MARK: - Variables

    let animationCalculator: ImageAnimationCalculatorProtocol

    // will be used for animation if no faces found
    let backupAnimationDataSource: AnimationDataSource

    let faceRecognitionMode: FaceRecognitionMode

    // MARK: - Init

    init(faceRecognitionMode: FaceRecognitionMode,
            animationCalculator: ImageAnimationCalculatorProtocol,
            backupAnimationDataSource: AnimationDataSource) {
        self.faceRecognitionMode = faceRecognitionMode
        self.animationCalculator = animationCalculator
        self.backupAnimationDataSource = backupAnimationDataSource
    }

    convenience init(faceRecognitionMode: FaceRecognitionMode,
            animationDependencies: ImageAnimationDependencies,
            backupAnimationDataSource: AnimationDataSource) {
        self.init(faceRecognitionMode: faceRecognitionMode,
                  animationCalculator: ImageAnimationCalculator(animationDependencies: animationDependencies),
                  backupAnimationDataSource: backupAnimationDataSource)
    }

    // MARK: - Public

    func buildAnimation(forImage: UIImage, forViewPortSize viewPortSize: CGSize) -> ImageAnimation {
        let image = forImage
        guard let faceRect = findFace(inImage: image) else {
            return backupAnimationDataSource.buildAnimation(forImage: image, forViewPortSize: viewPortSize)
        }

        let imageSize = image.size

        let startScale: CGFloat = animationCalculator.buildRandomScale(imageSize: imageSize, viewPortSize: viewPortSize)
        let endScale: CGFloat = animationCalculator.buildRandomScale(imageSize: imageSize, viewPortSize: viewPortSize)

        let scaledStartImageSize = imageSize.scaled(startScale)
        let scaledEndImageSize = imageSize.scaled(endScale)

        let startFromFace = Bool.random

        var imageStartPosition: CGPoint = CGPoint.zero
        if startFromFace {
            let faceRectScaled = faceRect.applying(CGAffineTransform(scaleX: startScale, y: startScale))
            imageStartPosition = animationCalculator.buildFacePosition(faceRect: faceRectScaled,
                                                                       imageSize: scaledStartImageSize,
                                                                       viewPortSize: viewPortSize)
        } else {
            imageStartPosition = animationCalculator.buildPinnedToEdgesPosition(imageSize: scaledStartImageSize,
                                                                                viewPortSize: viewPortSize)
        }


        var imageEndPosition: CGPoint = CGPoint.zero
        if !startFromFace {
            let faceRectScaled = faceRect.applying(CGAffineTransform(scaleX: endScale, y: endScale))
            imageEndPosition = animationCalculator.buildFacePosition(faceRect: faceRectScaled,
                                                                     imageSize: scaledEndImageSize,
                                                                     viewPortSize: viewPortSize)
        } else {
            imageEndPosition = animationCalculator.buildOppositeAnglePosition(startPosition: imageStartPosition,
                                                                              imageSize: scaledEndImageSize,
                                                                              viewPortSize: viewPortSize)
        }

        let duration = animationCalculator.buildAnimationDuration()

        let imageStartState = ImageState(scale: startScale, position: imageStartPosition)
        let imageEndState = ImageState(scale: endScale, position: imageEndPosition)
        let imageTransition = ImageAnimation(startState: imageStartState, endState: imageEndState, duration: duration)

        return imageTransition
    }

    // MARK: - Private

    private func findFace(inImage: UIImage) -> CGRect? {
        switch faceRecognitionMode {
            case .group:
                return inImage.groupFacesRect()
            case .biggest:
                return inImage.biggestFaceRect()
        }
    }
}
