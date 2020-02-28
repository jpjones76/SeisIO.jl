export read_data, read_data!

note_fsrc!(S::GphysData, N::Array{Int64,1}, fmt::String, filestr::String, opts::String) = note!(S, N, string( "+source ¦ read_data!(S, ",
                          "\"", fmt,  "\", ",
                          "\"", filestr, "\", ",
                          opts, ")" ))

function src_track!(S::GphysData, j::Int64, nx::Array{Int64,1}, last_src::Array{Int64,1})
  n = length(nx)

  # Check existing channels for changes
  for i in 1:n
    if length(S.x[i]) > nx[i]
      last_src[i] = j
      nx[i] = length(S.x[i])
    end
  end

  # Add new channels
  if n < S.n
    δn = S.n - n
    append!(nx, zeros(Int64, δn))
    append!(last_src, zeros(Int64, δn))
    for i in n+1:S.n
      nx[i] = length(S.x[i])
      last_src[i] = j
    end
  end
  return nothing
end

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
    S = read_data(fmt, filestr [, keywords])
    read_data!(S, fmt, filestr [, keywords])

Read data in file format `fmt` matching file pattern `filestr` into SeisData object `S`.

    S = read_data(filestr [, keywords])
    read_data!(S, filestr [, keywords])

Read from files matching file pattern `filestr` into SeisData object `S`.
Calls `guess(filestr)` to identify the file type based on the first file
matching pattern `filestr`. Much slower than manually specifying file type.

* Formats: ah1, ah2, bottle, geocsv, geocsv.slist, lennartz, mseed, passcal, suds, sac, segy, seisio, slist, uw, win32
* Keywords: cf, full, jst, memmap, nx_add, nx_new, strict, swap, v, vl

This function is fully described in the official documentation at https://seisio.readthedocs.io/ in section **Time-Series Data File Formats**.

See also: SeisIO.KW, get_data, guess, rseis
""" read_data!
function read_data!(S::GphysData, fmt::String, fpat::Union{String, Array{String,1}};
  cf      ::String  = "",                 # win32 channel info file
  full    ::Bool    = false,              # full SAC/SEGY hdr
  jst     ::Bool    = true,               # are sample times JST (UTC+9)?
  memmap  ::Bool    = false,              # use mmap? (DANGEROUS)
  nx_add  ::Int64   = KW.nx_add,          # append nx_add to overfull channels
  nx_new  ::Int64   = KW.nx_new,          # new channel samples
  strict  ::Bool    = false,              # strict channel matching
  swap    ::Bool    = false,              # do byte swap?
  v       ::Integer = KW.v,               # verbosity level
  vl      ::Bool    = false               # verbose logging
  )

  # Variables for tracking changes
  N             = S.n
  fpat_is_array = isa(fpat, Array{String, 1})
  fmt_is_seisio = (fmt == "seisio")
  opt_strings   = String[]
  last_src      = zeros(Int64, S.n)
  nx            = [length(S.x[i]) for i in 1:S.n]

  if fpat_is_array
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
  else
    filestr = abspath(fpat)
    one_file = safe_isfile(filestr)
    if one_file == false
      files = ls(filestr)
    end
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
      for (j, fname) in enumerate(files)
        read_sac_file!(S, fname, fv, iv, cv, full, memmap, strict)
        src_track!(S, j, nx, last_src)
      end
    end

  elseif fmt_is_seisio
    if one_file
      read_data_seisio!(S, filestr, memmap, v)
    else
      for (j, fname) in enumerate(files)
        read_data_seisio!(S, fname, memmap, v)
        src_track!(S, j, nx, last_src)
      end
    end

  elseif ((fmt == "miniseed") || (fmt == "mseed"))
    setfield!(BUF, :swap, swap)
    if one_file
      read_mseed_file!(S, filestr, nx_new, nx_add, memmap, strict, v)
    else
      for (j, fname) in enumerate(files)
        read_mseed_file!(S, fname, nx_new, nx_add, memmap, strict, v)
        src_track!(S, j, nx, last_src)
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
      for (j, fname) in enumerate(files)
        read_ah1!(S, fname, full, memmap, strict, v)
        src_track!(S, j, nx, last_src)
      end
    end
    push!(opt_strings, string("full = ", full))

  elseif fmt == "ah2"
    if one_file
      read_ah2!(S, filestr, full, memmap, strict, v)
    else
      for (j, fname) in enumerate(files)
        read_ah2!(S, fname, full, memmap, strict, v)
        src_track!(S, j, nx, last_src)
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
      for (j, fname) in enumerate(files)
        read_geocsv_file!(S, fname, tspair, memmap)
        src_track!(S, j, nx, last_src)
      end
    end

  elseif fmt == "lennartz"
    if one_file
      read_slist!(S, filestr, true, memmap)
    else
      for (j, fname) in enumerate(files)
        read_slist!(S, fname, true, memmap)
        src_track!(S, j, nx, last_src)
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
      for (j, fname) in enumerate(files)
        read_segy_file!(S, fname, passcal, memmap, full, swap, strict)
        src_track!(S, j, nx, last_src)
      end
    end
    push!(opt_strings, string("full = ", full,
                              ", swap = ", swap))

  elseif fmt == "slist"
    if one_file
      read_slist!(S, filestr, false, memmap)
    else
      for (j, fname) in enumerate(files)
        read_slist!(S, fname, false, memmap)
        src_track!(S, j, nx, last_src)
      end
    end

  elseif fmt == "suds"
    if one_file
      append!(S, SUDS.read_suds(filestr, memmap=memmap, full=full, v=v))
    else
      for (j, fname) in enumerate(files)
        append!(S, SUDS.read_suds(fname, memmap=memmap, full=full, v=v))
        src_track!(S, j, nx, last_src)
      end
    end
    push!(opt_strings, string("full = ", full))

  elseif fmt == "uw"
    if one_file
      UW.uwdf!(S, filestr, full, memmap, strict, v)
    else
      for (j, fname) in enumerate(files)
        UW.uwdf!(S, fname, full, memmap, strict, v)
        src_track!(S, j, nx, last_src)
      end
    end
    push!(opt_strings, string("full = ", full))

  elseif fmt == "win32" || fmt =="win"
    if isa(fpat, Array{String, 1})
      for (j, f) in enumerate(fpat)
        readwin32!(S, f, cf, jst, nx_new, nx_add, memmap, strict, v)

        # here the list of files is already expanded, so this is accurate
        src_track!(S, j, nx, last_src)
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
  if !fmt_is_seisio
    if length(opt_strings) == 0
      opts = string("v = ", v, ", vl = ", vl)
    else
      push!(opt_strings, string("v = ", v, ", vl = ", vl))
      opts = join(opt_strings, ", ")
    end

    # Update all channels
    to_note = Int64[]
    if fpat_is_array
      for i in 1:S.n
        if last_src[i] > 0
          S.src[i] = files[last_src[i]]
          push!(to_note, i)
        end
      end
    else

      # Update existing channels first
      for i in 1:N
        if length(S.x[i]) > nx[i]
          S.src[i] = filestr
          push!(to_note, i)
        end
      end

      # Do new channels
      chan_view = view(S.src, N+1:S.n)
      fill!(chan_view , filestr)

      # Note new source
      append!(to_note, collect(N+1:S.n))

      # note filestr used in read
      if vl == false
          note_fsrc!(S, to_note, fmt, filestr, opts)

      # For verbose logging, note all files used in the read
      elseif one_file == false
        files = ls(filestr)
      end
    end

    # For verbose logging, any changed channel logs all files to :notes
    if vl && (one_file == false)
      for f in files
        note_fsrc!(S, to_note, fmt, f, opts)
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
