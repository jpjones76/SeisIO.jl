# SeisIO
A minimalist, platform-agnostic package for working with geophysical time series data.

## Dependencies
DSP, Requests, LightXML, PyPlot

# Current Functionality
SeisIO presently includes two web clients (FDSN and IRISws), readers for several seismic data formats, and writers for both SAC and a native "SeisData" format. A large number of utility functions allow synchronization and padding time gaps.

## Readable File Formats
* SAC:
* mini-SEED: readmseed
* SEG Y rev 0: readsegy
* SEG Y rev 0 (mod. PASSCAL/NMT): readsegy<sup>[1](#footnote1)</sup>
* SEG Y rev 1: readsegy
* Win32: readwin32<sup>[2](#footnote1)</sup>
* UW: readuw

There's also a wrapper for Lennartz-style ASCII (rlennasc) that correctly parses the one-line text header.

## Near-Real-Time Web Requests
Two easy wrappers for web requests are included: FDSNget and IRISget.

### FDSNget
`FDSNget` is a wrapper for FDSN data access via HTTP (e.g. http://service.iris.edu/fdsnws/).

#### An FDSN Example
The command sqeuence below downloads (up to) 10 data channels (outage-dependent) from 4 stations at Mt. St. Helens (WA, USA), deletes the two low-gain channels, fills in time gaps, plots the data, and saves to the current directory.
```
S = FDSNget(net="CC,UW", sta="SEP,SHW,HSR,VALT", cha="*", t=600)
S -= "SHW    ELZUW"
S -= "HSR    ELZUW"
ungap!(S)             # Remove time gaps
plotseis(S)           # Time-aligned plot
wsac(S)               # Save data to SAC files
```

### IRISget
Easy wrapper for near-real-time IRIS webserver requests. Uses the IRIS timeseries web service (http://service.iris.edu/irisws/timeseries/1/).

#### A Single-Channel Example
The command sequence below requests and saves to disk (roughly) the last 5 minutes of data from station TIMB (Timberline Lodge, Mt. Hood, OR, USA).
```
S = irisws(net="CC", sta="TIMB", cha="EHZ", t=300, fmt="miniseed")
wsac(S)
```

#### A Multi-Channel Example
This example command sequence requests 10 minutes of data from a May 2016 earthquake swarm at Mt. Hood, OR, USA.
```
STA = ["UW.HOOD.BHZ"; "UW.HOOD.BHN"; "UW.HOOD.BHE"; "CC.TIMB.EHZ"; "CC.TIMB.EHN"; "CC.TIMB.EHE"];
TS = "2016-05-16T14:50:00"; TE = 600;
S = IRISget(STA, s=TE, e=TE, sync=true);
wsac(S)
```

#### Note
* No station coordinates are returned from IRISget or irisws. The IRIS web server doesn't provide them.

## Combining data types
The following example shows how to combine data types (file data + web data, file data from different files/formats, etc). Because the standard readers all create either SeisObj or SeisData instances, they can be freely combined with the `+` operator. Note that using `+` will try to sync the times of any channels with matching IDs; readers try to set channel IDs automatically.

```
S1 = readsac("/data2/unsorted/why_did_you_email_me_a_1-day-long_SAC_file.sac")
S2 = FSDNget(net="UW", sta="MBW", cha="*", s="2016-03-17T00:00:00", t="2016-03-18T00:00:00")
S3 = readsegy("/data2/unsorted/howaredaylongsegyfilesevenpossible.segy", fmt="nmt")
S4 = readwin32("/data2/unsorted/ugh_not_another_1440_one-minute-long_files/*cnt", "/data2/unsorted/03_02_27_20170318.sjis.ch")
S = S1 + S2 + S3 + S4
```

<a name="footnote1">1</a>: PASSCAL/NMT/IRIS SEG Y files lack the standard 3600-byte header (3200-byte textural header + 400-byte file header); an added keyword (fmt="nmt") is required to parse them correctly. <a name="footnote1">2</a>: Unique among the seismic data readers, readwin32 has basic wildcard functionality for data file names, but it also requires a channel information file as a separate (second) argument. All data files matching the wild card are read in lexicographical order and synchronized.

# SeisData objects
The SeisData type is designed as a minimalist processable memory-resident object; that is, each SeisData object is meant to contain the minimum information required for routine analysis of continuous data. Type `?SeisData` at the Julia command prompt for details.

An individual channel from a SeisData object is a separate object class, SeisObj.

## Working with SeisData
SeisData structures can be manipulated with the following commands (see documentation). Many of these commands also provide functionality for interactions between SeisData and SeisObj.
* +, -, ==, isequal
* append!, push!
* delete!, deleteat!
* findid, findname, hasid, hasname, samehdr, search
* getindex, setindex!
* merge!
* note
* plotseis
* prune!, purge!, purge, sort!, sort, sync!, sync, ungap!, ungap
* rseis, wseis, wsac
* sizeof

### The "RandSeis" Collection
Random junk traces can be generated using `randseisdata()` and `randseisobj()`; empty channels in existing structures can be filled using `populate_seis!` and `populate_chan!`.
* `randseisdata(i)`, where `i` is an integer, generates `i` channels; `randseisdata()` with no arguments generates a random number of channels.
* Headers have pseudo-realistic names and values; data are Gaussian noise.
* Specify `c=true` to allow a small percentage of channels with campaign-style measurements (fs = 0).

# Loading and Saving Data
SeisData objects can be saved to a native binary file format or written to SAC.

## SeisData file format
`wseis(FNAME, S)` writes SeisData object `S` to `FNAME`.

## SAC file format
`wsac(S)` writes each channel in `S` to an auto-generated SAC file, one trace per file. By default, time stamps are written as the dependent variable.

### Advantages/Disadvantages of SAC
+ Very widely used.
- Data are only stored in single-precision format.
- Rudimentary time stamping. Time stamps aren't written by default (change with `ts=true`). If you **do** choose to write time stamps to SAC files, data are treated by SAC itself as unevenly spaced, generic `x-y` data (`LEVEN=0, IFTYPE=4`). This causes issues with SAC readers in many languages; most load timestamped data as the real part of a complex time series, with the time values in the imaginary part.

# Acknowledgements
mini-SEED routines are based on rdmseed.m for Matlab, written by by Francois Beauducel, Institut de Physique du Globe de Paris (France). Many thanks to Robert Casey and Chad Trabant (IRIS, USA) for discussions of IRIS web services, and Douglas Neuhauser (UC Berkeley Seismological Laboratory, USA) for discussions of the SAC data format.

# References
1. IRIS (2010), SEED Reference Manual: SEED Format Version 2.4, May 2010, IFDSN/IRIS/USGS, http://www.iris.edu
2. Trabant C. (2010), libmseed: the Mini-SEED library, IRIS DMC.
3. Steim J.M. (1994), 'Steim' Compression, Quanterra Inc.
4. Storchak, D.A., J. Schweitzer, P. Bormann (2003). The IASPEI Standard Seismic Phase List, Seismol. Res. Lett. 74, 6, 761-772.
