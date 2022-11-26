# vm_info

A more user-friendly version of Apple's [`vm_stat`](https://github.com/apple-oss-distributions/system_cmds/blob/main/vm_stat.tproj) 
utility that displays the same information but in human-readable units.

Also displays the same summary information as Activity Monitor. 

Sample output:

```
Mach Virtual Memory Statistics:
  Free:                   0.06 GB
  Active (pageable):      2.19 GB
  Inactive:               2.16 GB
  Speculative:            0.01 GB
  Throttled:              0.00 GB
  Wired (not pageable):   1.92 GB
  Purgeable:              0.05 GB
  File-backed (non-swap): 1.64 GB
  Anonymous:              2.73 GB
  Stored in compressor:   10.45 GB
  Used by compressor:     1.65 GB

Physical Memory:          8.00 GB
Memory Used:              6.30 GB
  App Memory:             2.68 GB
  Wired Memory:           1.92 GB
  Compressed:             1.65 GB
Cached Files:             1.68 GB
Swap Used:                3.06 GB

Memory Pressure:          55%
```

Build with `swift build` or build & run with `swift run`.
