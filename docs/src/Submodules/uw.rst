##
UW
##

The UW submodule extends functionality for the University of Washington (UW) file format(s).

The UW data format was created in the 1970s by the Pacific Northwest Seismic Network (PNSN), USA, for event archival. It remained in use through the 1990s. A UW event is described by a pickfile and a corresponding data file, whose filenames were identical except for the last character. The data file is self-contained; the pick file is not required to read raw trace data. However, station locations were stored in an external text file.

Only UW-2 data files are supported by SeisIO. We have only seen UW-1 data files in Exabyte tapes from the 1980s.

.. function:: uwpf(pf[, v])

Read UW-format seismic pick file `pf`. Returns a tuple of (SeisHdr, SeisSrc).

.. function:: uwpf!(W, pf[, v::Int64=KW.v])

Read UW-format seismic pick info from pickfile `f` into SeisEvent object `W`. Overwrites W.source and W.hdr with pickfile information. Keyword `v` controls verbosity.
