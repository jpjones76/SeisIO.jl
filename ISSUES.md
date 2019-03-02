# Known and Historic Issues

## Outstanding
* SeisData ID fields with Unicode characters are truncated when written to
the native SeisIO data format.

#### System- and Version-specific
* (**Unresolved**) Implicit package dependency `Arpack` (required by `Blosc`)
sometimes fails to build.
  + Affects: Linux 4.19.16-1-MANJARO (x86_64) with Julia 1.0.3-2
  + Impact: breaks native format file i/o
  + **Workaround**: upgrade to Julia 1.1.0 Generic Linux Binaries for x86 (64-bit)

## 2017-07-24
* (_Resolved_) `batch_read` is no longer useful. Julia 0.6.0 slowed `batch_read` execution time by roughly a factor of 4; it currently offers only ~10-20% speedup over standard file read times.
  + (Fix) 2018-08-07 `batch_read` removed
* (**Unresolved**) Rarely, `SeedLink!` can cause a Julia session to hang by failing to initialize a connection.

## 2017-01-24
* (_Resolved_) Type-stability is impossible in Julia when initializing with keyword arguments
  + (Fix) 2017-01-31 Deprecated keyword arguments in all SeisIO data types
* (_Resolved_) `readmseed` uses exorbitant amounts of memory
  + (Fix) 2017-07-16 `readmseed` rewrite
