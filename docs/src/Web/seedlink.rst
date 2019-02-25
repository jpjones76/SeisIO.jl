########
SeedLink
########

***************
SeedLink Client
***************

`SeedLink <https://www.seiscomp3.org/wiki/doc/applications/seedlink>`_ is a
TCP/IP-based data transmission protocol that allows near-real-time access to
data from thousands of geophysical monitoring instruments. See
:ref:`data keywords list <dkw>` and :ref:`channel id syntax <cid>` for options.

.. function:: SeedLink!(S, chans, KWs)
.. function:: SeedLink!(S, chans, patts, KWs)
.. function:: S = SeedLink(chans, KWs)

| Standard keywords: fmt, opts, q, si, to, v, w, y
| SL keywords: gap, kai, mode, port, refresh, safety, x\_on\_err
| Other keywords: ``u`` specifies the URL without "http://"

Initiate a SeedLink session in DATA mode to feed data from channels ``chans`` with
selection patterns ``patts`` to SeisData structure ``S``. A handle to a TCP
connection is appended to ``S.c``.Data are periodically parsed until the
connection is closed. One SeisData object can support multiple connections,
provided that each connection's streams feed unique channels.


Argument Syntax
---------------

**chans**

Channel specification can use any of the following options:

1. A comma-separated String where each pattern follows the syntax NET.STA.LOC.CHA.DFLAG, e.g. UW.TDH..EHZ.D. Use "?" to match any single character.
2. An Array{String,1} with one pattern per entry, following the above syntax.
3. The name of a configuration text file, with one channel pattern per line; see :ref:`Channel Configuration File syntax<ccfg>`.

**patts**
Data selection patterns. See SeedLink documentation; syntax is identical.


Special Rules
-------------

1. SeedLink follows unusual rules for wild cards in ``sta`` and ``patts``:
    a. ``*`` is not a valid SeedLink wild card.
    b. The LOC and CHA fields can be left blank in ``sta`` to select all locations and channels.
2. DO NOT feed one data channel with multiple SeedLink streams. This can have severe consequences:
    a. A channel fed by multiple live streams will have many small time sequences out of order. ``merge!`` is not guaranteed to fix it.
    b. SeedLink will almost certainly crash.
    c. Your data may be corrupted.
    d. The Julia interpreter can freeze, requiring ``kill -9`` on the process.
    e. This is not an "issue". There will never be a workaround. It's what happens when one intentionally causes TCP congestion on one's own machine while writing to open data streams in memory. Hint: don't do this.

Special Methods
---------------
* ``close(S.c[i])`` ends SeedLink connection ``i``.
* ``!deleteat(S.c, i)`` removes a handle to closed SeedLink connection ``i``.

******************
SeedLink Utilities
******************

.. function:: SL_info(v, url)

Retrieve SeedLink information at verbosity level **v** from **url**. Returns XML as a string. Valid strings for **L** are ID, CAPABILITIES, STATIONS, STREAMS, GAPS, CONNECTIONS, ALL.


.. function:: has_sta(sta[, u=url, port=n])

| SL keywords: gap, port
| Other keywords: ``u`` specifies the URL without "http://"

Check that streams exist at `url` for stations `sta`, formatted
NET.STA. Use "?" to match any single character. Returns true for
stations that exist. `sta` can also be the name of a valid config
file or a 1d string array.

Returns a BitArray with one value per entry in `sta.`

.. function:: has_stream(cha::Union{String,Array{String,1}}, u::String)

| SL keywords: gap, port
| Other keywords: ``u`` specifies the URL without "http://"

Check that streams with recent data exist at url `u` for channel spec
`cha`, formatted NET.STA.LOC.CHA.DFLAG, e.g. "UW.TDH..EHZ.D,
CC.HOOD..BH?.E". Use "?" to match any single character. Returns `true`
for streams with recent data.

`cha` can also be the name of a valid config file.

.. function:: has_stream(sta::Array{String,1}, sel::Array{String,1}, u::String, port=N::Int, gap=G::Real)
   :noindex:

| SL keywords: gap, port
| Other keywords: ``u`` specifies the URL without "http://"

If two arrays are passed to has_stream, the first should be
formatted as SeedLink STATION patterns (formated "SSSSS NN", e.g.
["TDH UW", "VALT CC"]); the second be an array of SeedLink selector
patterns (formatted LLCCC.D, e.g. ["??EHZ.D", "??BH?.?"]).
