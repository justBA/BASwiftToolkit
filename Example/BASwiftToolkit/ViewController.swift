//
//  ViewController.swift
//  BASwiftToolkit
//
//  Created by An B. Nguyen on 05/08/2023.
//  Copyright (c) 2023 An B. Nguyen. All rights reserved.
//

import UIKit
import BASwiftToolkit
import Combine
import Network

class ViewController: UIViewController {

    @IBOutlet weak var reachabilityLabel: UILabel!
    // MARK: - Properties
        private var cancellables = Set<AnyCancellable>()
        private let monitorQueue = DispatchQueue(label: "monitor")
        
        // MARK: - Lifecycle
        override func viewDidLoad() {
            super.viewDidLoad()
            self.reachabilityLabel.textColor = .black
            self.observeNetworkStatus()
        }
        
        // MARK: - Network Status Observation
        private func observeNetworkStatus() {
            NWPathMonitor()
                .publisher(queue: monitorQueue)
                .receive(on: DispatchQueue.main)
                .sink { [weak self] status in
                    self?.reachabilityLabel.text = status == .satisfied ?
                        "Connection is OK" : "Connection lost"
                }
                .store(in: &cancellables)
        }

}

