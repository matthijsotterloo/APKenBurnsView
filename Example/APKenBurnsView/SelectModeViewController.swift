//
// Created by Nickolay Sheika on 6/13/16.
// Copyright (c) 2016 CocoaPods. All rights reserved.
//

import Foundation
import UIKit
import APKenBurnsView

class SelectModeViewController: UITableViewController {

    // MARK: - Private Variables

    fileprivate var dataSource: [String]!

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        dataSource = ["family1", "family2", "nature1", "nature2"]
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)

        var faceRecognitionMode: APKenBurnsViewFaceRecognitionMode = .none
        if segue.identifier == "Biggest" {
           faceRecognitionMode = .biggest
        }
        if segue.identifier == "Group" {
            faceRecognitionMode = .group
        }
        let destination = segue.destination as! KenBurnsViewController
        destination.faceRecoginitionMode = faceRecognitionMode
        destination.dataSource = dataSource
    }
}
