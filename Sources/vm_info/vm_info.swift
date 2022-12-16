import Foundation

@main
public struct vm_info {
    public static func main() {
        let port = mach_host_self()
        
        var vm_stat = vm_statistics64_data_t()
        
        var count = mach_msg_type_number_t(
            MemoryLayout<vm_statistics64_data_t>.stride /
            MemoryLayout<integer_t>.stride)
        
        let kr = withUnsafeMutablePointer(to: &vm_stat) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                host_statistics64(port, HOST_VM_INFO64, $0, &count)
            }
        }
        
        guard kr == KERN_SUCCESS else {
            fatalError("host_statistics64 failed: \(kr)")
        }
        
        var pageSize = vm_size_t()
        guard host_page_size(port, &pageSize) == KERN_SUCCESS else {
            fatalError("host_page_size failed")
        }
        
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = .useGB
        formatter.allowsNonnumericFormatting = false
        formatter.countStyle = .memory
        formatter.includesActualByteCount = false
        formatter.zeroPadsFractionDigits = true
        
        let physicalMemory = ProcessInfo.processInfo.physicalMemory
        
        func fmt(_ pageCount: natural_t) -> String {
            formatter.string(fromByteCount: Int64(pageCount) * Int64(pageSize))
        }
        
        // Information shown by vm_stat
        print("""
            Mach Virtual Memory Statistics:
              Free:                   \(fmt(vm_stat.free_count - vm_stat.speculative_count))
              Active (pageable):      \(fmt(vm_stat.active_count))
              Inactive:               \(fmt(vm_stat.inactive_count))
              Speculative:            \(fmt(vm_stat.speculative_count))
              Throttled:              \(fmt(vm_stat.throttled_count))
              Wired (not pageable):   \(fmt(vm_stat.wire_count))
              Purgeable:              \(fmt(vm_stat.purgeable_count))
              File-backed (non-swap): \(fmt(vm_stat.external_page_count))
              Anonymous:              \(fmt(vm_stat.internal_page_count))
              Stored in compressor:   \(fmt(natural_t(vm_stat.total_uncompressed_pages_in_compressor)))
              Used by compressor:     \(fmt(vm_stat.compressor_page_count))
            
            """)
        
        let physicalPages = natural_t(physicalMemory / UInt64(pageSize))
        
        formatter.allowedUnits = .useAll
        
        var swapusage = xsw_usage()
        var size = MemoryLayout<xsw_usage>.size
        sysctlbyname("vm.swapusage", &swapusage, &size, nil, 0)
        
        var memorystatus_level = Int()
        size = MemoryLayout<Int>.size
        sysctlbyname("kern.memorystatus_level", &memorystatus_level, &size, nil, 0)
        
        print("""
            Activity Monitor:
             Memory Pressure:         \(100 - memorystatus_level)%
             Physical Memory:         \(fmt(physicalPages))
             Memory Used:             \(fmt(physicalPages - vm_stat.available))
               App Memory:            \(fmt(vm_stat.app))
               Wired Memory:          \(fmt(vm_stat.wire_count))
               Compressed:            \(fmt(vm_stat.compressor_page_count))
             Cached Files:            \(fmt(vm_stat.cached))
             Swap Used:               \(fmt(natural_t(swapusage.xsu_used / UInt64(pageSize))))
            """)
        
        // Sum all the 'MEM' values from `top`, which match the 'Memory' column in activity monitor.
        // Fetching task_basic_info_64 for all processes, to do this programatically, would require
        // the com.apple.system-task-ports.read entitlement. It's not currently possible to add
        // entitlements to tools built with Swift Package Manager.
        if #available(macOS 10.15.4, *) {
            let pipe = Pipe()
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/top")
            process.arguments = ["-l", "1", "-stats", "mem"]
            process.standardOutput = pipe
            try! process.run()
            let stdout = try! pipe.fileHandleForReading.readToEnd()!
            var rsizeTotal = UInt64(0)
            var mem = false
            for var line in String(data: stdout, encoding: .utf8)!.components(separatedBy: .newlines) {
                line = line.trimmingCharacters(in: .whitespacesAndNewlines)
                guard mem else {
                    if line.hasPrefix("MEM") {
                        mem = true
                    }
                    continue
                }
                if line.isEmpty { continue }
                var num = UInt64(line.trimmingCharacters(in: .decimalDigits.inverted))!
                if line.hasSuffix("M") { num *= 1024 * 1024 }
                else if line.hasSuffix("K") { num *= 1024 }
                else { preconditionFailure() }
                rsizeTotal += num;
            }
            print("""
                
                Process Footprint:        \(fmt(natural_t(rsizeTotal / UInt64(pageSize))))
                """)
        }
    }
}

extension vm_statistics64_data_t {
    var app: natural_t {
        internal_page_count - purgeable_count
    }
    
    var cached: natural_t {
        purgeable_count + external_page_count
    }
    
    var available: natural_t {
        free_count + external_page_count - speculative_count
    }
}
