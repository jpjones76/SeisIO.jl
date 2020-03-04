export read_quake

@doc """
    Ev = read_quake(fmt, file [, keywords])

Read data in file format `fmt` from `file` into SeisEvent object `Ev`.
* Formats: suds, qml, uw
* Keywords: full, v

Note: because earthquake data are usually discrete, self-contained files, no "in-place" version of `read_quake` exists, and  `read_quake` doesn't support wildcards in the file string.

See also: `read_data`, `get_data`, `read_meta`, `UW.readuwevt`
""" read_quake
function read_quake(fmt::String, fname::String;
  full    ::Bool    = false,              # full header
  v       ::Integer = KW.v                # verbosity level
  )

  if fmt == "suds"
    Ev = SUDS.readsudsevt(fname, full=full, v=v)
  elseif fmt == "uw"
    Ev = UW.readuwevt(fname, full=full, v=v)
  elseif fmt in ("qml", "quakeml")
    hdr, source = read_qml(fname)
    Ev = SeisEvent(hdr = hdr[1], source = source[1])
  end
  return Ev
end
