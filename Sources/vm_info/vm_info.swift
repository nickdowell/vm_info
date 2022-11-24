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
        
        // Infomataion shown by Activity Monitor
        print("""
            Physical Memory:          \(fmt(physicalPages))
            Memory Used:              \(fmt(physicalPages - vm_stat.available))
              App Memory:             \(fmt(vm_stat.app))
              Wired Memory:           \(fmt(vm_stat.wire_count))
              Compressed:             \(fmt(vm_stat.compressor_page_count))
            Cached Files:             \(fmt(vm_stat.cached))
            Swap Used:                \(fmt(vm_stat.swap))
            """)
    }
}

extension vm_statistics64_data_t {
    var app: natural_t {
        internal_page_count - purgeable_count
    }
    
    var cached: natural_t {
        purgeable_count + external_page_count
    }
    
    var swap: natural_t {
        natural_t(swapouts - swapins) // Not verified
    }
    
    var available: natural_t {
        free_count + external_page_count - speculative_count
    }
}
