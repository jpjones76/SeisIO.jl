.. _seishdf:

#######
SeisHDF
#######

This submodule contains dedicated support for seismic subformats of the HDF5 file format.

********************
Additional Functions
********************

.. _asdfwaux:
.. function:: asdf_waux(fname, path, X)

Write *X* to AuxiliaryData/path in file *fname*. If an object already exists at
AuxiliaryData/path, it will be deleted and overwritten with *X*.

.. function:: asdf_rqml(fpat)

Read QuakeXML (qml) from ASDF file(s) matching file string pattern `fpat`. Returns:

* `H`, Array{SeisHdr,1}
* `R`, Array{SeisSrc,1}

.. _asdfwqml:
.. function:: asdf_wqml(fname, H, R[, keywords])
.. function:: asdf_wqml(fname, EV[, keywords])

Write to ASDF "QuakeML " group in file *fname*. In the above function calls, **H** can be a SeisHdr or Array{SeisHdr, 1}; **R** can be a SeisSource or Array{SeisSource, 1}; **EV** can be a SeisEvent or Array{SeisEvent, 1}.

Supported Keywords
******************
.. csv-table::
  :header: KW, Type, Default, Meaning
  :delim: |
  :widths: 1, 1, 1, 4

  ovr   | Bool      | false     | Overwrite data in existing traces?
  v     | Integer   | 0         | verbosity

.. function:: read_asdf_evt(filestr, event_id[, keywords])
.. function:: read_asdf_evt(filestr[, keywords])

Read data in seismic HDF5 format with ids matching *event_id* from files
matching pattern *filestr*. Returns an array of SeisEvent structures. With only one input argument, all event IDs are read.

Keywords:

* msr: (Bool) read full (MultiStageResp) instrument response?
* v: (Integer) verbosity level

.. function:: scan_hdf5(h5file)
.. function:: scan_hdf5(hdf, level="trace")

Scan HDF5 archive *h5file* and return station names with waveform data contained therein as a list of strings formatted "nn.sssss" (network.station).

Set level="trace" to return channel names with waveform data as a list of strings formatted "nn.sssss.ll.ccc" (network.station.location.channel).
