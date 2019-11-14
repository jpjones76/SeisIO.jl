export read_quake

@doc """
    Ev = read_quake(fmt, file [, keywords])

Read data in file format `fmt` from `file` into SeisEvent object `Ev`.

| Format      | String          | Notes                                       |

|:---         |:---             |:----                                        |
| PC-SUDS     | suds            |                                             |
| QuakeML     | qml, quakeml    | only reads first event from file            |
| UW          | uw              |                                             |


|KW       | Used By   | Type    | Default   | Meaning                         |
|:---     |:---       |:---     |:---       |:---                             |
| full    | suds, uw  | Bool    | false     | read full header into `:misc`?  |
| v       | all       | Int64   | 0         | verbosity                       |

### Notes on Functionality
* No "in-place" version of `read_quake` exists because earthquake data are
usually discrete, self-contained files.
* `read_quake` doesn't use file wildcards. See `?UW.readuwevt` for help with UW
file string syntax.

See also: read_data, get_data, read_meta
""" read_quake
function read_quake(fmt::String, fname::String;
  full    ::Bool    = false,              # full header
  v       ::Int64   = KW.v                # verbosity level
  )

  Ev = (
    if fmt == "suds"
      SUDS.readsudsevt(fname, full=full, v=v)
    elseif fmt == "uw"
      UW.readuwevt(fname, full=full, v=v)
    elseif fmt in ("qml", "quakeml")
      hdr, source = read_qml(fname)
      SeisEvent(hdr = hdr[1], source = source[1])
    end
    )
  return Ev
end
