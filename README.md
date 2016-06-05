# SeisIO
A minimalist, platform-agnostic package for working with geophysical time series data.

# Documentation
http://seisio.readthedocs.org

# Current Functionality
SeisIO presently includes three web clients, readers for several data formats, and writers for both SAC and a native format. Utility functions allow synchronization, seamless data merging, and padding time gaps.

### Web clients
* SeedLink
* FDSN
* IRIS timeseries

### Readable File Formats
* SAC <sup>(a)</sup>
* mini-SEED
* SEG Y (PASSCAL/NMT) <sup>(a)</sup>
* SEG Y (Standard)
* Win32
* UW

<sup>(a)</sup> Supported by ``batch_read``.

# Acknowledgements
mini-SEED routines are based on rdmseed.m for Matlab, written by by Francois Beauducel, Institut de Physique du Globe de Paris (France). Many thanks to Robert Casey and Chad Trabant (IRIS, USA) for discussions of IRIS web services, and Douglas Neuhauser (UC Berkeley Seismological Laboratory, USA) for discussions of the SAC data format.

# References
1. IRIS (2010), SEED Reference Manual: SEED Format Version 2.4, May 2010, IFDSN/IRIS/USGS, http://www.iris.edu
2. Trabant C. (2010), libmseed: the Mini-SEED library, IRIS DMC.
3. Steim J.M. (1994), 'Steim' Compression, Quanterra Inc.
