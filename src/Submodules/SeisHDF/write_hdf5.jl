@doc """
    write_hdf5( hdf_out::String, S::GphysData[, KWs] )

Write data to file `hdf_out` from structure `S` in a seismic HDF5 format.

    write_hdf5( hdf_out::String, W::SeisEvent[, KWs] )

Write data to file `hdf_out` from structure `W` in a seismic HDF5 format.
If the format doesn't record event header and source info, only `W.data` is
stored.

## Keywords
#### GphysData
|KW           | Type      | Default   | Meaning                               |
|:---         |:---       |:---       |:---                                   |
| add         | Bool      | false     | Add new traces to file as needed?     |
| chans       | ChanSpec  | 1:S.n     | Channels to write to file             |
| len         | Period    | Day(1)    | Length of new traces added to file    |
| ovr         | Bool      | false     | Overwrite data in existing traces?    |
| tag         | String    | ""        | Tag for trace names in ASDF volumes   |
| v           | Int64     | 0         | verbosity                             |

#### SeisEvent
|KW           | Type      | Default   | Meaning                               |
|:---         |:---       |:---       |:---                                   |
| chans       | ChanSpec  | 1:S.data.n| Channels to write to file             |
| tag         | String    | ""        | Tag for trace names in ASDF volumes   |
| v           | Int64     | 0         | verbosity                             |

## Write Methods
### Add (add = true)
This KW determines the start and end times of all data in `chans`, and
initializes new traces (filled with NaNs) of length = `len`.

#### ASDF behavior
Mode `add=true` follows these steps in this order:
1. Determine times of all data in `S[chans]` and all traces in "Waveforms/".
1. If data lie outside existing trace bounds, new traces are initialized.
1. For each segment in `S[chans]`:
  + Merge the header data in `S[chans]` into the relevant station XML.
  + Overwrite part of the relevant trace in `Waveforms/`.

Thus, unless `len` exactly matches the time boundaries of each segment in `S`,
the traces created will be intentionally larger.

### Overwrite (ovr = true)
If `ovr=true` is specified, but `add=false`, `write_hdf5` *only* overwrites
*existing* data in `hdf_out`.
* No new trace data objects are created in `hdf_out`.
* No new file is created. If `hdf_out` doesn't exist, nothing happens.
* If no traces in `hdf_out` overlap segments in `S`, `hdf_out` isn't modified.
* In ASDF format, station XML is merged in channels that are partly overwritten.

!!! warning

    `add=true`/`ovr=true` changes `:t` on file to begin at an exact sample time.

See also: read_hdf5
""" write_hdf5
function write_hdf5(file::String, S::GphysData;
  chans     ::Union{Integer, UnitRange, Array{Int64,1}} = Int64[], # channels
  add       ::Bool      = false,            # add traces
  fmt       ::String    = "asdf",           # data format
  len       ::Period    = Day(1),           # length of added traces
  ovr       ::Bool      = false,            # overwrite trace data
  tag       ::String    = "",               # trace tag (ASDF)
  v         ::Int64     = KW.v              # verbosity
  )

  chans = mkchans(chans, S.n)
  if fmt == "asdf"
    write_asdf(file, S, chans, add=add, len=len, ovr=ovr, tag=tag, v=v)
  else
    error("Unknown file format (possibly NYI)!")
  end

  return nothing
end

function write_hdf5(file::String, C::GphysChannel;
  add       ::Bool      = false,            # add traces
  fmt       ::String    = "asdf",           # data format
  len       ::Period    = Day(1),           # length of added traces
  ovr       ::Bool      = false,            # overwrite trace data
  v         ::Int64     = KW.v              # verbosity
  )

  S = SeisData(C)
  write_hdf5(file, S, fmt=fmt, ovr=ovr, v=v)
  return nothing
end

function write_hdf5(file::String, W::SeisEvent;
  chans     ::Union{Integer, UnitRange, Array{Int64,1}} = Int64[], # channels
  fmt       ::String    = "asdf",           # data format
  tag       ::String    = "",               # trace tag (ASDF)
  v         ::Int64     = KW.v              # verbosity
  )

  S = getfield(W, :data)
  chans = mkchans(chans, S.n)
  if fmt == "asdf"
    H = getfield(W, :hdr)
    R = getfield(W, :source)
    write_asdf(file, S, chans, evid=H.id, tag=tag, v=v)
    asdf_wqml(file, [H], [R], v=v)
  else
    error("Unknown file format (possibly NYI)!")
  end

  return nothing
end
