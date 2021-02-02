SeisIO v1.2.0
2021-02-02

SeisIO v1.2.0 introduces `scan_seed` for rapid scans of mini-SEED files.

# 1. **Public API Changes**

## scan_seed
`scan_seed` is a new function in `SeisIO.SEED` intended to quickly scan large mini-SEED files. (Feature request, issue #62)
  + `scan_seed` reports changes within a mini-SEED file, including:
    - Samples per channel (KW `npts`)
    - Gaps (KW `ngaps`), or exact gap times (`seg_times=true`)
    - Changes in sampling frequency (KW `nfs`), or exact times of fs changes (`fs_times=true`)
  + Reports to stdout (suppress with `quiet=true`)
  + Returns a String array of comma-delineated outputs, one entry per channel.
  + Please open feature request Issues to request scans for additional changes.
  + This won't interact directly with online SEED requests. To apply `scan_seed` to an online request for a seed volume, use `w=true` to dump the raw request to disk, and scan the file(s) created by the download.

## rescale
New processing function `rescale!` quickly scales data in a structure and adjusts the gain.

## SAC updates
* Read/write support for SAC file version 7 (SAC v102.0).
* New function `fill_sac_evh!` in SeisIO.Quake fills some SeisEvent header data from a SAC file.

# 2. **Bug Fixes**
* `ungap!` should now work correctly on a channel whose only time gap occurs before the last sample. (Fixes issue #74)
* Attempting to call `resample!` on a NodalData object should no longer error. Merged PR #68 from tclements/Resample. (Fixes issue #65.)
* `writesac` should now write begin time (word 5) in a way that never shifts sample times, even by subsample values. (Fixes issue #60)
* Parsing a SEED Blockette [061] now correctly returns the stage, rather than nothing.
* Quake submodule
  + Calling `writesac` on a SeisEvent object now always writes event header values to the correct byte indices for SAC v101 and above.

# 3. **Consistency, Performance**
* Performance will be slightly better when reading large files whose data contain many negative time gaps. (Partly fixes issue #72)
  + This change decreases memory consumption in this "end member" case by ~75% and read time by ~40%.
  + The memory overhead for extremely large files containing very many negative time gaps is still untenable; this very rare end-member case cannot be fixed without fundamentally rewriting all SeisIO timekeeping.
* NodalData now uses AbstractArray{Float32, 2} for the :data field, rather than Array{Float32, 2}. (Merged PR #66 from tclements/Nodal)
* NodalLoc (:loc field of NodalData) now has x, y, z subfields. (Merged PR #64 from tclements/NodalLoc)
* `convert` has been expanded:
  + `convert(NodalData, S)` and `convert(EventTraceData, S)` should now work for all GphysData subtypes.
  + `convert(NodalChannel, C)` and `convert(EventChannel, C)` should now work for all GphysChannel subtypes.
  + `EventTraceData(S::T) where T<:GphysData` is now aliased to `convert(EventTraceData, C)`.
  + `EventChannel(C::T) where T<:GphysChannel` is now defined as an alias to `convert(EventChannel, C)`.
  + `NodalData(S::T) where T<:GphysData` is now aliased to `convert(NodalData, C)`.
  + `NodalChannel(C::T) where T<:GphysChannel` is now defined as an alias to `convert(NodalChannel, C)`.
  + `SeisData(S::T) where T<:GphysData` should now be aliased to `convert(SeisData, S)` for all GphysData subtypes.
* `merge!` has been extended to GphysChannel subtypes. For this functionality, the values of each field in (:id, :fs, :gain, :loc, :resp) must be either the same for both objects, or unset in at least one object.

# 4. **Developer API Changes**
* Added function `t_bounds(t, Δ)` to the suite of internal time functions. This is a fast, low-memory alternative to `t_win(t, Δ)[1]`.
* Added function `cmatch_p!(C1, C2)` for partial matches of paired GphysChannels. Given two objects C1, C2, if the values of (:id, :fs, :gain, :loc, :resp) are the same between objects, or unset, they're considered a match. On a match, unset field values are filled automatically from the corresponding field of the matching object.

# 5. **Documentation**
* Merged pull request #77 from tclements/master. (Fixes issue #76)
