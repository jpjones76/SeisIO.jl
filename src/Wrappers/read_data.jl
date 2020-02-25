export read_data, read_data!

function read_data_seisio!(S::SeisData, filestr::String, memmap::Bool, v::Integer)
  S_in = rseis(filestr, memmap=memmap)
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
    read_data!(S, fmt, filestr [, keywords])

Read data in file format `fmt` matching file pattern `filestr` into SeisData object `S`.

    S = read_data(filestr [, keywords])
    read_data!(S, filestr [, keywords])

Read from files matching file pattern `filestr` into SeisData object `S`.
Calls `guess(filestr)` to identify the file type based on the first file
matching pattern `filestr`. Much slower than manually specifying file type.

## Supported File Formats
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

### Keywords
|KW      | Used By  | Type    | Default   | Meaning                         |
|:---    |:---      |:---     |:---       |:---                             |
|cf      | win32    | String  | ""        | win32 channel info filestr      |
|full    | ah1, ah2 | Bool    | false     | read full header into `:misc`?  |
|        | sac      |         |           |                                 |
|        | segy     |         |           |                                 |
|        | suds     |         |           |                                 |
|        | uw       |         |           |                                 |
|memmap  | *        | Bool    | false     | use mmap to read files? [^1]    |
|nx_add  | bottle   | Int64   | 360000    | min. increase when resizing `:x`|
|        | mseed    |         |           |                                 |
|        | win32    |         |           |                                 |
|nx_new  | bottle   | Int64   | 86400000  | `length(C.x)` for new channels  |
|        | mseed    |         |           |                                 |
|        | win32    |         |           |                                 |
|jst     | win32    | Bool    | true      | are sample times JST (UTC+9)?   |
|strict  | *        | Bool    | false     | strict channel matching?        |
|swap    | mseed    | Bool    | true      | byte swap?                      |
|        | passcal  |         |           |                                 |
|        | segy     |         |           |                                 |
|v       | *        | Int64   | 0         | verbosity                       |
|vl      | *        | Bool    | false     | verbose logging to :notes [^2]  |

[^1]: potentially dangerous; Julia SIGSEGV handling is undocumented.
[^2]: verbose logging adds one line to `:notes` for each file read.

See official SeisIO documentation for performance tips associated with KWs.

## SeisIO native format
`read_data("seisio", ...)` is a convenience wrapper that reads only the first SeisIO object that can be converted to a SeisData structure from each file. For more complicated read operations on SeisIO files, use `rseis`.

## Examples
1. `S = read_data("uw", "99011116541W", full=true)`
    + Read UW-format data file `99011116541W`
    + Store full header information in `:misc`
2. `read_data!(S, "sac", "MSH80*.SAC", "strict=true")`
    + Read SAC-format files matching string pattern `MSH80*.SAC`
    + Read into existing SeisData object `S`
    + Only continue a channel that matches on `:id`, `:fs`, and `:gain`
3. `S = read_data("win32", "20140927*.cnt", cf="20140927*ch", nx_new=360000)`
    + Read win32-format data files with names matching pattern `2014092709*.cnt`
    + Use ASCII channel information filenames that match pattern `20140927*ch`
    + Assign new channels an initial size of `nx_new` samples

See also: SeisIO.KW, get_data, guess, rseis
""" read_data!
function read_data!(S::GphysData, fmt::String, fpat::Union{String, Array{String,1}};
  full    ::Bool    = false,              # full SAC/SEGY hdr
  cf      ::String  = "",                 # win32 channel info file
  jst     ::Bool    = true,               # are sample times JST (UTC+9)?
  memmap  ::Bool    = false,              # use mmap? (DANGEROUS)
  nx_add  ::Int64   = KW.nx_add,          # append nx_add to overfull channels
  nx_new  ::Int64   = KW.nx_new,          # new channel samples
  strict  ::Bool    = false,              # strict channel matching
  swap    ::Bool    = false,              # do byte swap?
  v       ::Integer = KW.v,               # verbosity level
  vl      ::Bool    = false               # verbose logging
  )

  N = S.n
  if isa(fpat, Array{String, 1})
    one_file = false
    files = String[]
    for f in fpat
      ff = abspath(f)
      if safe_isfile(ff)
        push!(files, realpath(ff)) # deal with symlinks
      else
        append!(files, ls(ff))
      end
    end
    new_chan_src = files
  else
    filestr = abspath(fpat)
    one_file = safe_isfile(filestr)
    if one_file == false
      files = ls(filestr)
    end
    new_chan_src = nothing
  end
  if fmt != "seisio"
    opt_strings = Array{String,1}(undef, 0)
  end

  if fmt == "sac"
    fv = getfield(BUF, :sac_fv)
    iv = getfield(BUF, :sac_iv)
    cv = getfield(BUF, :sac_cv)
    checkbuf_strict!(fv, 70)
    checkbuf_strict!(iv, 40)
    checkbuf_strict!(cv, 192)
    if one_file
      read_sac_file!(S, filestr, fv, iv, cv, full, memmap, strict)
    else
      for fname in files
        read_sac_file!(S, fname, fv, iv, cv, full, memmap, strict)
      end
    end

  elseif fmt == "seisio"
    if one_file
      read_data_seisio!(S, filestr, memmap, v)
    else
      for fname in files
        read_data_seisio!(S, fname, memmap, v)
      end
    end

  elseif ((fmt == "miniseed") || (fmt == "mseed"))
    setfield!(BUF, :swap, swap)
    if one_file
      read_mseed_file!(S, filestr, nx_new, nx_add, memmap, strict, v)
    else
      for fname in files
        read_mseed_file!(S, fname, nx_new, nx_add, memmap, strict, v)
      end
    end
    push!(opt_strings, string("swap = ", swap,
                              ", nx_new = ", nx_new,
                              ", nx_add = ", nx_add))

# ============================================================================
# Data formats that aren't SAC, SEISIO, or SEED begin here and are alphabetical
# by first KW

  elseif fmt == "ah1"
    if one_file
      read_ah1!(S, filestr, full, memmap, strict, v)
    else
      for fname in files
        read_ah1!(S, fname, full, memmap, strict, v)
      end
    end
    push!(opt_strings, string("full = ", full))

  elseif fmt == "ah2"
    if one_file
      read_ah2!(S, filestr, full, memmap, strict, v)
    else
      for fname in files
        read_ah2!(S, fname, full, memmap, strict, v)
      end
    end
    push!(opt_strings, string("full = ", full))

  elseif fmt == "bottle"
    read_bottle!(S, filestr, nx_new, nx_add, memmap, strict, v)
    push!(opt_strings, string("nx_new = ", nx_new,
                              ", nx_add = ", nx_add))

  elseif fmt in ("geocsv", "geocsv.tspair", "geocsv", "geocsv.slist")
    tspair = (fmt == "geocsv" || fmt == "geocsv.tspair")
    if one_file
      read_geocsv_file!(S, filestr, tspair, memmap)
    else
      for fname in files
        read_geocsv_file!(S, fname, tspair, memmap)
      end
    end

  elseif fmt == "lennartz"
    if one_file
      read_slist!(S, filestr, true, memmap)
    else
      for fname in files
        read_slist!(S, fname, true, memmap)
      end
    end

  elseif fmt == "segy" || fmt == "passcal"
    passcal = fmt == "passcal"
    # buf     = getfield(BUF, :buf)
    # shorts  = getfield(BUF, :int16_buf)
    # ints    = getfield(BUF, :int32_buf)
    # checkbuf!(buf, 240)

    if one_file
      # read_segy_file!(S, filestr, buf, shorts, ints, passcal, swap, memmap, full, strict)
      read_segy_file!(S, filestr, passcal, memmap, full, swap, strict)
    else
      for fname in files
        read_segy_file!(S, fname, passcal, memmap, full, swap, strict)
      end
    end
    push!(opt_strings, string("full = ", full,
                              ", swap = ", swap))

  elseif fmt == "slist"
    if one_file
      read_slist!(S, filestr, false, memmap)
    else
      for fname in files
        read_slist!(S, fname, false, memmap)
      end
    end

  elseif fmt == "suds"
    if one_file
      append!(S, SUDS.read_suds(filestr, memmap=memmap, full=full, v=v))
    else
      for fname in files
        append!(S, SUDS.read_suds(fname, memmap=memmap, full=full, v=v))
      end
    end
    push!(opt_strings, string("full = ", full))

  elseif fmt == "uw"
    if one_file
      UW.uwdf!(S, filestr, full, memmap, strict, v)
    else
      for fname in files
        UW.uwdf!(S, fname, full, memmap, strict, v)
      end
    end
    push!(opt_strings, string("full = ", full))

  elseif fmt == "win32" || fmt =="win"
    if isa(fpat, Array{String, 1})
      for f in fpat
        readwin32!(S, f, cf, jst, nx_new, nx_add, memmap, strict, v)
      end
    else
      readwin32!(S, filestr, cf, jst, nx_new, nx_add, memmap, strict, v)
    end
    push!(opt_strings, string("cf = \"", abspath(cf), "\"",
                              ", jst = ", jst,
                              ", nx_new = ", nx_new,
                              ", nx_add = ", nx_add))

  else
    error("Unknown file format!")
  end

  # ===================================================================
  # logging
  if fmt != "seisio"
    if length(opt_strings) == 0
      opts = string("v = ", v, ", vl = ", vl)
    else
      push!(opt_strings, string("v = ", v, ", vl = ", vl))
      opts = join(opt_strings, ", ")
    end

    if new_chan_src == nothing
      chan_view = view(S.src, N+1:S.n)
      fill!(chan_view , filestr)
      if vl && (one_file == false)
        files = ls(filestr)
        for f in files
          note!(S, N+1:S.n, string( "+source ¦ read_data!(S, ",
                                    "\"", fmt,  "\", ",
                                    "\"", f, "\", ",
                                    opts, ")" )
                )
        end
      else
        note!(S, N+1:S.n, string( "+source ¦ read_data!(S, ",
                                  "\"", fmt,  "\", ",
                                  "\"", filestr, "\", ",
                                  opts, ")" )
              )
      end
    else
      for (j,i) in enumerate(N+1:S.n)
        S.src[i] = new_chan_src[j]
      end
      if vl
        for f in files
          note!(S, N+1:S.n, string( "+source ¦ read_data!(S, ",
                                    "\"", fmt,  "\", ",
                                    "\"", f, "\", ",
                                    opts, ")" )
                )
        end
      end
    end
  end

  # ===================================================================
  return nothing
end

@doc (@doc read_data!)
function read_data(fmt::String, filestr::Union{String, Array{String, 1}};
  full    ::Bool    = false,              # full SAC/SEGY hdr
  cf      ::String  = "",                 # win32 channel info file
  jst     ::Bool    = true,               # are sample times JST (UTC+9)?
  memmap  ::Bool    = false,              # use mmap? (DANGEROUS)
  nx_add  ::Int64   = KW.nx_add,          # append nx_add to overfull channels
  nx_new  ::Int64   = KW.nx_new,          # new channel samples
  strict  ::Bool    = false,              # strict channel matching
  swap    ::Bool    = false,              # do byte swap?
  v       ::Integer = KW.v,               # verbosity level
  vl      ::Bool    = false               # verbose logging
  )

  S = SeisData()
  read_data!(S, fmt, filestr,
    full    = full,
    cf      = cf,
    jst     = jst,
    memmap  = memmap,
    nx_add  = nx_add,
    nx_new  = nx_new,
    strict  = strict,
    swap    = swap,
    v       = v,
    vl      = vl
    )
  return S
end

function read_data(filestr::Union{String, Array{String, 1}};
  full    ::Bool    = false,              # full SAC/SEGY hdr
  cf      ::String  = "",                 # win32 channel info file
  jst     ::Bool    = true,               # are sample times JST (UTC+9)?
  memmap  ::Bool    = false,              # use mmap? (DANGEROUS)
  nx_add  ::Int64   = KW.nx_add,          # append nx_add to overfull channels
  nx_new  ::Int64   = KW.nx_new,          # new channel samples
  strict  ::Bool    = false,              # strict channel matching
  v       ::Integer = KW.v,               # verbosity level
  vl      ::Bool    = false               # verbose logging
  )

  if isa(filestr, String)
    if safe_isfile(filestr)
      g = guess(filestr)
    else
      files = ls(filestr)
      g = guess(files[1])
    end
  else
    g = guess(filestr[1])
  end
  S = SeisData()
  read_data!(S, g[1], filestr,
    full    = full,
    cf      = cf,
    jst     = jst,
    memmap  = memmap,
    nx_add  = nx_add,
    nx_new  = nx_new,
    strict  = strict,
    swap    = g[2],
    v       = v,
    vl      = vl
    )
  return S
end

function read_data!(S::GphysData, filestr::Union{String, Array{String, 1}};
  full    ::Bool    = false,              # full SAC/SEGY hdr
  cf      ::String  = "",                 # win32 channel info file
  jst     ::Bool    = true,               # are sample times JST (UTC+9)?
  memmap  ::Bool    = false,              # use mmap? (DANGEROUS)
  nx_add  ::Int64   = KW.nx_add,          # append nx_add to overfull channels
  nx_new  ::Int64   = KW.nx_new,          # new channel samples
  strict  ::Bool    = false,              # strict channel matching
  v       ::Integer = KW.v,               # verbosity level
  vl      ::Bool    = false               # verbose logging
  )

  if isa(filestr, String)
    if safe_isfile(filestr)
      g = guess(filestr)
    else
      files = ls(filestr)
      g = guess(files[1])
    end
  else
    g = guess(filestr[1])
  end

  read_data!(S, g[1], filestr,
    full    = full,
    cf      = cf,
    jst     = jst,
    memmap  = memmap,
    nx_add  = nx_add,
    nx_new  = nx_new,
    strict  = strict,
    swap    = g[2],
    v       = v,
    vl      = vl
    )
  return S
end
