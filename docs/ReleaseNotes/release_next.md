SeisIO vx.x.x
xxxx-xx-xx

[one-line summary]

# 1. **Public API Changes**

## New

# 2. **Bug Fixes**

# 3. **Consistency, Performance**
* `filtfilt!`: breaking combinations of data and filter parameters should now be identical in `DSP.filtfilt` and `SeisIO.filtfilt!`, even on Float32 data.
  + Implicit feature request from issue #82.
  + This should never force data conversion to Float64. (We already test this.)
  + It's always possible to choose a filter that outputs NaNs, but the two filtering functions should now behave identically in this regard.

# 4. **Developer API Changes**

# 5. **Documentation**
