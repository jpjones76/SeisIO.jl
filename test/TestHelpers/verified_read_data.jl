function verified_read_data!(S::GphysData, fmt::String, fpat::Union{String, Array{String,1}};
  full    ::Bool    = false,              # full SAC/SEGY hdr
  cf      ::String  = "",                 # win32 channel info file
  jst     ::Bool    = true,               # are sample times JST (UTC+9)?
  nx_add  ::Int64   = KW.nx_add,          # append nx_add to overfull channels
  nx_new  ::Int64   = KW.nx_new,          # new channel samples
  strict  ::Bool    = true,
  swap    ::Bool    = false,              # do byte swap?
  v       ::Int64   = KW.v,               # verbosity level
  vl      ::Bool    = false,              # verbose logging
  allow_empty::Bool = false
  )

  read_data!(S, fmt, fpat,
    full    = full,
    cf      = cf,
    jst     = jst,
    nx_add  = nx_add,
    nx_new  = nx_new,
    strict  = strict,
    swap    = swap,
    v       = v,
    vl      = vl
    )

  basic_checks(S, allow_empty = allow_empty)
  return nothing
end

function verified_read_data(fmt::String, fpat::Union{String, Array{String,1}};
  full    ::Bool    = false,              # full SAC/SEGY hdr
  cf      ::String  = "",                 # win32 channel info file
  jst     ::Bool    = true,               # are sample times JST (UTC+9)?
  nx_add  ::Int64   = KW.nx_add,          # append nx_add to overfull channels
  nx_new  ::Int64   = KW.nx_new,          # new channel samples
  strict  ::Bool    = true,
  swap    ::Bool    = false,              # do byte swap?
  v       ::Int64   = KW.v,               # verbosity level
  vl      ::Bool    = false,              # verbose logging
  allow_empty::Bool = false
  )

  S = read_data(fmt, fpat,
    full    = full,
    cf      = cf,
    jst     = jst,
    nx_add  = nx_add,
    nx_new  = nx_new,
    strict  = strict,
    swap    = swap,
    v       = v,
    vl      = vl
    )

  basic_checks(S, allow_empty = allow_empty)
  return S
end
