# vm_info

A more user-friendly version of Apple's [`vm_stat`](https://github.com/apple-oss-distributions/system_cmds/blob/main/vm_stat.tproj) 
utility that displays the same information but in human-readable units.

Also displays the same summary information as Activity Monitor. 

Sample output:

```
Mach Virtual Memory Statistics:
  Free:                   0.12 GB
  Active (pageable):      2.22 GB
  Inactive:               2.32 GB
  Speculative:            0.14 GB
  Throttled:              0.00 GB
  Wired (not pageable):   2.02 GB
  Purgeable:              0.13 GB
  File-backed (non-swap): 2.07 GB
  Anonymous:              2.61 GB
  Stored in compressor:   9.17 GB
  Used by compressor:     1.18 GB

Physical Memory:          8.00 GB
Memory Used:              5.81 GB
  App Memory:             2.48 GB
  Wired Memory:           2.02 GB
  Compressed:             1.18 GB
Cached Files:             2.20 GB
Swap Used:                3.06 GB
```

Build with `swift build` or build & run with `swift run`.
