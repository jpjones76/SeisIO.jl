SeisIO v1.2.1
2020-03-22

Fixes a nuisance issue with `writesac`, updates the tutorials, and improves the consistency between SeisIO and DSP.jl filtering.

# 1. **Public API Changes**
None

# 2. **Bug Fixes**
* The tutorial installer now checks that IJupyer is installed before trying to load it.

# 3. **Consistency, Performance**

### filtfilt!
SeisIO filtering should now be more robust on Float32 data. Breaking combinations of data and filter parameters should now be nearly identical for `DSP.filtfilt` and `SeisIO.filtfilt!`. (Implicit feature request from issue #82)

### writesac
Reverted to creating SAC v6 files by default.
* Create SAC v7 files by using keyword argument `nvhdr=7`.
* This is a change from older versions:
  + SeisIO v1.2.0 only created SAC v7 files.
  + Earlier SeisIO releases only created SAC v6 files.

The goal of this change is to match the SAC file version of data requests. IRIS requests in SAC format still download v6 files as of this SeisIO release. If that changes, we will update the default value of `nvhdr`.

*Dev Note*: as it turns out, SAC itself is not forward-compatible with respect to file header version (variable NVHDR in SAC files). A file with NVHDR=7 (SAC v102.0) **will not** read into SAC v101.6a. We were very surprised to discover this, as the file format documentation suggests that v7 of the SAC file header should work with v6 readers.

# 4. **Developer API Changes**
None

# 5. **Documentation**

### Tutorial Updates
* Added basic information to the first tutorial for users who are completely new to Jupyter.
* Added code, suggestions, and workarounds to the Processing tutorial to help with potential issues inherent to near-real-time data requests.
