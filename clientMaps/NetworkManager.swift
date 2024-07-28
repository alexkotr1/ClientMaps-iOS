import Network
import Foundation

class NetworkManager {
    private var monitor: NWPathMonitor?
    private var timeoutTimer: Timer?
    private var hasHandledNetworkChange = false

    func startMonitoring(timeout: TimeInterval, completion: @escaping (Bool) -> Void) {
        hasHandledNetworkChange = false
        monitor = NWPathMonitor()
        monitor?.pathUpdateHandler = { [weak self] path in
            guard let self = self else { return }
            if path.status == .satisfied {
                if !self.hasHandledNetworkChange {
                    self.hasHandledNetworkChange = true
                    print("Network is available")
                    self.timeoutTimer?.invalidate()
                    self.monitor?.cancel()
                    completion(true)
                }
            } else {
                print("Network is unavailable")
                if !self.hasHandledNetworkChange {
                    self.hasHandledNetworkChange = true
                    self.timeoutTimer?.invalidate()
                    self.monitor?.cancel()
                    completion(false)
                }
            }
        }
        
        let queue = DispatchQueue(label: "Monitor")
        monitor?.start(queue: queue)
        timeoutTimer = Timer.scheduledTimer(withTimeInterval: timeout, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            if !self.hasHandledNetworkChange {
                self.hasHandledNetworkChange = true
                self.monitor?.cancel()
                print("Network check timed out")
            }
        }
    }
}
