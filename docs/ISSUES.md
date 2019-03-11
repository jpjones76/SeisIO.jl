# Known Issues

## Oustanding
* wseis cannot write a SeisData object if a channel contains no data. 

## Possibly resolved
* Rarely, `SeedLink!` used to cause a Julia session to hang by failing to initialize a connection.
  + This behavior has not been seen in 1.5 years and might have changed with dependency bug fixes.

## System- and Version-specific
* Implicit package dependency `Arpack` (required by `Blosc`)
sometimes fails to build.
  + Affects: Linux 4.19.16-1-MANJARO (x86_64) with Julia 1.0.3-2
  + Impact: breaks native format file i/o
  + **Workaround**: upgrade to Julia 1.1.0 Generic Linux Binaries for x86 (64-bit)
