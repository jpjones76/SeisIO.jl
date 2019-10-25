export read_data, read_data!

function read_data_seisio!(S::SeisData, filestr::String, v::Int64)
  S_in = rseis(filestr)
  L = length(S_in)
  for i in 1:L
    if typeof(S_in[i]) == SeisChannel
      push!(S, S_in[i])
      break
    elseif typeof(S_in[i]) <: GphysChannel
      C = convert(SeisChannel, S_in[i])
      push!(S, C)
      break
    elseif typeof(S_in[i]) == SeisData
      append!(S, S_in[i])
      break
    elseif typeof(S_in[i]) <: GphysData
      S1 = convert(SeisData, S_in[i])
      append!(S, S1)
      break
    elseif typeof(S_in[i]) == SeisEvent
      (v > 0) && @warn(string("Obj ", i, " is type SeisEvent: only reading :data field"))
      S1 = convert(SeisData, getfield(S_in[i], :data))
      append!(S, S1)
      break
    else
      (v > 0) && @warn(string("Obj ", i, " skipped (Type incompatible with read_data)"))
    end
  end
  return nothing
end

@doc """
    read_data

Generic wrapper for reading file data.

    S = read_data(fmt, filestr [, keywords])

Read data in file format `fmt` matching file pattern `filestr` into a new
SeisData object `S`.

    S = read_data(filestr [, keywords])

Read from files matching file pattern `filestr` into a new SeisData object `S`.
Calls `guess(filestr)` to identify the file type based on the first file
matching pattern `filestr`. Much slower than manually specifying file type.

This single-string syntax will not work with SACPZ or SEED RESP files; `guess`
cannot detect them.

    read_data!(S, fmt, filestr [, keywords])

Read data in file format `fmt` matching file pattern `filestr` into an existing
SeisData object `S`.

    read_data!(S, filestr [, keywords])

As above, but calls `guess(filestr)` to set the format based on the first file
matching pattern `filestr`.

| Format                    | String          |
| :---                      | :---            |
| AH-1                      | ah1             |
| AH-2                      | ah2             |
| Bottle                    | bottle          |
| GeoCSV, time-sample pair  | geocsv          |
| GeoCSV, sample list       | geocsv.slist    |
| Lennartz SLIST            | lennartz        |
| Mini-SEED                 | mseed           |
| PASSCAL SEG Y             | passcal         |
| PC-SUDS                   | suds            |
| SAC                       | sac             |
| SEG Y (rev 0 or rev 1)    | segy            |
| SEISIO                    | seisio          |
| SLIST (ASCII sample list) | slist           |
| UW                        | uw              |
| Win32                     | win32           |

|KW      | Used By  | Type    | Default   | Meaning                         |
|:---    |:---      |:---     |:---       |:---                             |
|cf      | win32    | String  | ""        | win32 channel info filestr      |
|full    | sac      | Bool    | false     | read full header into `:misc`?  |
|        | segy     |         |           |                                 |
|        | suds     |         |           |                                 |
|        | uw       |         |           |                                 |
|        | ah       |         |           |                                 |
|nx_add  | mseed    | Int64   | 360000    | min. increase when resizing `:x`|
|        | bottle   |         |           |                                 |
|        | win32    |         |           |                                 |
|nx_new  | mseed    | Int64   | 86400000  | `length(C.x)` for new channels  |
|        | bottle   |         |           |                                 |
|        | win32    |         |           |                                 |
|jst     | win32    | Bool    | true      | are sample times JST (UTC+9)?   |
|swap    | mseed    | Bool    | true      | byte swap?                      |
|v       | all      | Int64   | 0         | verbosity                       |

### Format-Dependent Performance Tips

#### `mseed`, `win32`, `bottle`
Adjust `nx_new` and `nx_add` based on expected data vector lengths. If the
largest data vector has `Nmax` samples, and the smallest has `Nmin`, we
recommend `nx_new`≈`Nmin` and `nx_add`≈`Nmax - Nmin`.

Default values can be changed in SeisIO keywords, e.g.,
```julia
SeisIO.KW.nx_new = 60000
SeisIO.KW.nx_add = 360000
```

The system-wide defaults are `nx_new=86400000` and `nx_add=360000`. Using these
values with very small jobs will greatly decrease performance.

#### SeisIO native format

`read_data("seisio", ...)` largely exists as a convenience wrapper; it reads
only the first SeisIO object from each file that can be converted to a SeisData
structure. For more complicated read operations on SeisIO files, use `rseis`.

## Examples
1. `S = read_data("uw", "99011116541W", full=true)`
    + Read UW-format data file `99011116541W`
    + Store full header information in `:misc`
2. `read_data!(S, "sac", "MSH80*.SAC")`
    + Read SAC-format files matching string pattern `MSH80*.SAC`
    + Read into existing SeisData object `S`
3. `S = read_data("win32", "20140927*.cnt", cf="20140927*ch", nx_new=360000)`
    + Read win32-format data files with names matching pattern `2014092709*.cnt`
    + Use ASCII channel information filenames that match pattern `20140927*ch`
    + Assign new channels an initial size of `nx_new` samples

See also: SeisIO.KW, get_data, guess, rseis
""" read_data!
function read_data!(S::GphysData, fmt::String, filestr::String;
  full    ::Bool    = false,              # full SAC/SEGY hdr
  cf      ::String  = "",                 # win32 channel info file
  jst     ::Bool    = true,               # are sample times JST (UTC+9)?
  nx_add  ::Int64   = KW.nx_add,          # append nx_add to overfull channels
  nx_new  ::Int64   = KW.nx_new,          # new channel samples
  swap    ::Bool    = false,              # do byte swap?
  v       ::Int64   = KW.v                # verbosity level
  )

  one_file = safe_isfile(filestr)

  if fmt == "sac"
    fv = getfield(BUF, :sac_fv)
    iv = getfield(BUF, :sac_iv)
    cv = getfield(BUF, :sac_cv)
    checkbuf_strict!(fv, 70)
    checkbuf_strict!(iv, 40)
    checkbuf_strict!(cv, 192)
    if one_file
      read_sac_file!(S, filestr, fv, iv, cv, full)
    else
      files = ls(filestr)
      for fname in files
        read_sac_file!(S, fname, fv, iv, cv, full)
      end
    end

  elseif fmt == "seisio"
    if one_file
      read_data_seisio!(S, filestr, v)
    else
      files = ls(filestr)
      for fname in files
        read_data_seisio!(S, fname, v)
      end
    end


  elseif ((fmt == "miniseed") || (fmt == "mseed"))
    setfield!(BUF, :swap, swap)
    if one_file
      read_mseed_file!(S, filestr, v, nx_new, nx_add)
    else
      files = ls(filestr)
      for fname in files
        read_mseed_file!(S, fname, v, nx_new, nx_add)
      end
    end

# ============================================================================
# Data formats that aren't SAC, SEISIO, or SEED begin here and are alphabetical
# by first KW

  elseif fmt == "ah1"
    if one_file
      read_ah1!(S, filestr, v=v, full=full)
    else
      files = ls(filestr)
      for fname in files
        read_ah1!(S, fname, v=v, full=full)
      end
    end

  elseif fmt == "ah2"
    if one_file
      read_ah2!(S, filestr, v=v, full=full)
    else
      files = ls(filestr)
      for fname in files
        read_ah2!(S, fname, v=v, full=full)
      end
    end

  elseif fmt == "bottle"
    read_bottle!(S, filestr, v, nx_new, nx_add)

  elseif fmt in ("geocsv", "geocsv.tspair", "geocsv", "geocsv.slist")
    tspair = (fmt == "geocsv" || fmt == "geocsv.tspair")
    if one_file
      read_geocsv_file!(S, filestr, tspair)
    else
      files = ls(filestr)
      for fname in files
        read_geocsv_file!(S, fname, tspair)
      end
    end

  elseif fmt == "lennartz"
    if one_file
      read_slist!(S, filestr, lennartz=true)
    else
      files = ls(filestr)
      for fname in files
        read_slist!(S, fname, lennartz=true)
      end
    end

  elseif fmt == "segy" || fmt == "passcal"
    passcal = fmt == "passcal"
    buf     = getfield(BUF, :buf)
    shorts  = getfield(BUF, :int16_buf)
    ints    = getfield(BUF, :int32_buf)
    checkbuf!(buf, 240)

    if one_file
      append!(S, read_segy_file(filestr, buf, shorts, ints, passcal, swap, full))
    else
      files = ls(filestr)
      for fname in files
        append!(S, read_segy_file(fname, buf, shorts, ints, passcal, swap, full))
      end
    end

  elseif fmt == "slist"
    if one_file
      read_slist!(S, filestr)
    else
      files = ls(filestr)
      for fname in files
        read_slist!(S, fname)
      end
    end

  elseif fmt == "suds"
    if one_file
      append!(S, SUDS.read_suds(filestr, full=full, v=v))
    else
      files = ls(filestr)
      for fname in files
        append!(S, SUDS.read_suds(fname, full=full, v=v))
      end
    end

  elseif fmt == "uw"
    if one_file
      append!(S, UW.uwdf(filestr, v=v, full=full))
    else
      files = ls(filestr)
      for fname in files
        append!(S, UW.uwdf(fname, v=v))
      end
    end

  elseif fmt == "win32" || fmt =="win"
    readwin32!(S, filestr, cf, jst=jst, nx_new=nx_new, nx_add=nx_add, v=v)

  else
    error("Unknown file format!")
  end

  return nothing
end

@doc (@doc read_data!)
function read_data(fmt::String, filestr::String;
  full    ::Bool    = false,              # full SAC/SEGY hdr
  cf      ::String  = "",                 # win32 channel info file
  jst     ::Bool    = true,               # are sample times JST (UTC+9)?
  nx_add  ::Int64   = KW.nx_add,          # append nx_add to overfull channels
  nx_new  ::Int64   = KW.nx_new,          # new channel samples
  swap    ::Bool    = false,              # do byte swap?
  v       ::Int64   = KW.v                # verbosity level
  )

  S = SeisData()
  read_data!(S, fmt, filestr,
    full    = full,
    cf      = cf,
    jst     = jst,
    nx_add  = nx_add,
    nx_new  = nx_new,
    swap    = swap,
    v       = v
    )
  return S
end

function read_data(filestr::String;
  full    ::Bool    = false,              # full SAC/SEGY hdr
  cf      ::String  = "",                 # win32 channel info file
  jst     ::Bool    = true,               # are sample times JST (UTC+9)?
  nx_add  ::Int64   = KW.nx_add,          # append nx_add to overfull channels
  nx_new  ::Int64   = KW.nx_new,          # new channel samples
  v       ::Int64   = KW.v                # verbosity level
  )

  if safe_isfile(filestr)
    g = guess(filestr)
  else
    files = ls(filestr)
    g = guess(files[1])
  end
  S = SeisData()
  read_data!(S, g[1], filestr,
    full    = full,
    cf      = cf,
    jst     = jst,
    nx_add  = nx_add,
    nx_new  = nx_new,
    swap    = g[2],
    v       = v
    )
  return S
end

function read_data!(S::GphysData, filestr::String;
  full    ::Bool    = false,              # full SAC/SEGY hdr
  cf      ::String  = "",                 # win32 channel info file
  jst     ::Bool    = true,               # are sample times JST (UTC+9)?
  nx_add  ::Int64   = KW.nx_add,          # append nx_add to overfull channels
  nx_new  ::Int64   = KW.nx_new,          # new channel samples
  v       ::Int64   = KW.v                # verbosity level
  )

  if safe_isfile(filestr)
    g = guess(filestr)
  else
    files = ls(filestr)
    g = guess(files[1])
  end

  read_data!(S, g[1], filestr,
    full    = full,
    cf      = cf,
    jst     = jst,
    nx_add  = nx_add,
    nx_new  = nx_new,
    swap    = g[2],
    v       = v
    )
  return S
end
