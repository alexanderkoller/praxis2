import Foundation

func localNetworkIP() -> String {
    var address = "127.0.0.1"
    var ifaddr: UnsafeMutablePointer<ifaddrs>?
    guard getifaddrs(&ifaddr) == 0, let firstAddr = ifaddr else { return address }
    defer { freeifaddrs(ifaddr) }

    var ptr = firstAddr
    while true {
        let flags = Int32(ptr.pointee.ifa_flags)
        let isUp = (flags & IFF_UP) != 0
        let isLoopback = (flags & IFF_LOOPBACK) != 0

        if isUp && !isLoopback,
           ptr.pointee.ifa_addr.pointee.sa_family == UInt8(AF_INET) {
            var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
            if getnameinfo(ptr.pointee.ifa_addr, socklen_t(ptr.pointee.ifa_addr.pointee.sa_len),
                           &hostname, socklen_t(hostname.count),
                           nil, 0, NI_NUMERICHOST) == 0 {
                let candidate = String(cString: hostname)
                if candidate.hasPrefix("192.") || candidate.hasPrefix("10.") || candidate.hasPrefix("172.") {
                    address = candidate
                    break
                }
            }
        }
        guard let next = ptr.pointee.ifa_next else { break }
        ptr = next
    }
    return address
}
