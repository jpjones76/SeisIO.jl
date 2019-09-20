@doc """
    S = read_hdf5(filestr [, keywords])
    read_hdf5!(S, filestr [, keywords])

Read data in seismic HDF5 format from files matching pattern `filestr`.

|KW     | Type      | Default | Meaning                                       |
|:---   |:---       |:---     |:---                                           |
| id    | String    | "..."   | id pattern, formated nn.sss.ll.ccc            |
|       |           |         |  (net.sta.loc.cha); FDSN-style wildcards [^1] |
| s     | TimeSpec  | [^2]    | start time                                    |
| t     | TimeSpec  | [^2]    | termination (end) time                        |
| msr   | Bool      | true    | read full (MultiStageResp) instrument resp?   |
| v     | Int64     | 0       | verbosity                                     |

[^1] A question mark ('?') is a wildcard for a single character (exactly one); an asterisk ('*') is a wildcard for zero or more characters
[^2] If unset, (s,t) ≈ (21 September 1677, 11 April 2262), the limits of timekeeping (relative to the Unix epoch) with Int64 nanoseconds

See also: SeisIO.KW, get_data, read_data, read_meta

!!! warning

    `s`, `t` are strongly recommended, unless the intent is to read many GB of data into memory.
""" read_hdf5!
function read_hdf5!(S::GphysData, filestr::String;
  fmt ::String                = "asdf",                 # data format
  id  ::Union{String, Regex}  = "...",                  # id string
  s   ::TimeSpec              = unset_s,                # start time
  t   ::TimeSpec              = unset_t,                # termination (end) time
  msr ::Bool                  = true,                   # read multistage response?
  v   ::Int64                 = KW.v                    # verbosity
  )

  one_file = safe_isfile(filestr)

  if fmt == "asdf"
    if one_file
      append!(S, read_asdf(filestr, id, s, t, msr, v))
    else
      files = ls(filestr)
      for fname in files
        append!(S, read_asdf(fname, id, s, t, msr, v))
      end
    end

  else
    error("Unknown file format (possibly NYI)!")
  end

  return nothing
end

@doc (@doc read_hdf5!)
function read_hdf5(filestr::String;
  fmt ::String                = "asdf",                 # data format
  id  ::Union{String, Regex}  = "...",                  # id string
  s   ::TimeSpec              = unset_s,                # start time
  t   ::TimeSpec              = unset_t,                # termination (end) time
  msr ::Bool                  = true,                   # read multistage response?
  v   ::Int64                 = KW.v                    # verbosity
  )

  S = SeisData()
  read_hdf5!(S, filestr,
    fmt     = fmt,
    id      = id,
    s       = s,
    t       = t,
    msr     = msr,
    v       = v
    )
  return S
end
