//
//  KenBurnsViewController.swift
//  APKenBurnsView
//
//  Created by Nickolay Sheika on 04/21/2016.
//  Copyright (c) 2016 Nickolay Sheika. All rights reserved.
//

import UIKit
import APKenBurnsView

class KenBurnsViewController: UIViewController {

    // MARK: - Outlets

    @IBOutlet weak var kenBurnsView: APKenBurnsView!

    // MARK: - Public Variables

    var faceRecoginitionMode: APKenBurnsViewFaceRecognitionMode = .none
    var dataSource: [String]!

    // MARK: - Private Variables

    fileprivate var index = 0

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationController!.isNavigationBarHidden = true

        kenBurnsView.faceRecognitionMode = faceRecoginitionMode
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        self.kenBurnsView.startAnimations()
    }
}

extension KenBurnsViewController: APKenBurnsViewDataSource {
    func nextImage(forKenBurnsView: APKenBurnsView) -> UIImage? {
        let image = UIImage(named: dataSource[dataSource.index(self.index, offsetBy: 0)])!
        self.index = index == dataSource.count - 1 ? 0 : index + 1
        return image
    }
}
