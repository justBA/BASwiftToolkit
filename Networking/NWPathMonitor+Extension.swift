//
//  NWPathMonitor+Extension.swift
//  BASwiftToolkit
//
//  Created by An Nguyen on 08/05/2023.
//

import Network
import Combine

// MARK: - NWPathMonitor Subscription
extension NWPathMonitor {
    class NetworkStatusSubscription<S: Subscriber>: Subscription where S.Input == NWPath.Status {
        private let subscriber: S?
          
        private let monitor: NWPathMonitor
        private let queue: DispatchQueue

        init(subscriber: S,
           monitor: NWPathMonitor,
           queue: DispatchQueue) {

          self.subscriber = subscriber
          self.monitor = monitor
          self.queue = queue
        }
          
        func request(_ demand: Subscribers.Demand) {
                  monitor.pathUpdateHandler = { [weak self] path in
                      guard let self = self else { return }
                      _ = self.subscriber?.receive(path.status)
                  }
                  monitor.start(queue: queue)
              }
              
              func cancel() {
                  monitor.cancel()
              }
        }
}

// MARK: - NWPathMonitor Publisher
extension NWPathMonitor {
    public struct NetworkStatusPublisher: Publisher {
        public typealias Output = NWPath.Status
        public typealias Failure = Never

        private let monitor: NWPathMonitor
        private let queue: DispatchQueue

        init(monitor: NWPathMonitor, queue: DispatchQueue) {
           self.monitor = monitor
           self.queue = queue
        }

        public func receive<S>(subscriber: S) where S : Subscriber, Never == S.Failure, NWPath.Status == S.Input {
           let subscription = NetworkStatusSubscription(subscriber: subscriber,
                                                        monitor: monitor,
                                                        queue: queue)
           subscriber.receive(subscription: subscription)
        }
        
    }

    public func publisher(queue: DispatchQueue) -> NWPathMonitor.NetworkStatusPublisher {
       return NetworkStatusPublisher(monitor: self,
                                     queue: queue)
    }
}
