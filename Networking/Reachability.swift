//
//  Reachability.swift
//  BASwiftToolkit
//
//  Created by An Nguyen on 08/05/2023.
//

import SwiftUI
import Combine
import Network

public class Reachability: ObservableObject {
    private var cancellables = Set<AnyCancellable>()
    private let monitorQueue = DispatchQueue(label: "monitor")
    @Published var networkStatus: NWPath.Status = .satisfied
    
    public init() {
        NWPathMonitor()
            .publisher(queue: monitorQueue)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                self?.networkStatus = status
            }
            .store(in: &cancellables)
    }
}
