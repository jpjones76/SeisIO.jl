@doc """
    S = read_hdf5(filestr, s::TimeSpec, t::TimeSpec, [, keywords])
    read_hdf5!(S, filestr, s::TimeSpec, t::TimeSpec, [, keywords])

Read data in seismic HDF5 format from files matching pattern `filestr`.

`s`, `t` are required arguments but can be any Type ∈ (DateTime, Real, String);
type `?timespec` for more information about how these are interpreted.

|KW     | Type      | Default   | Meaning                                     |
|:---   |:---       |:---       |:---                                         |
| id    | String    | "*"       | id pattern, formated nn.sss.ll.ccc          |
|       |           |           |  (net.sta.loc.cha); FDSN wildcards [^1]     |
| msr   | Bool      | true      | read full (MultiStageResp) instrument resp? |
| v     | Int64     | 0         | verbosity                                   |

[^1] A question mark ('?') is a wildcard for a single character; an asterisk ('*') is a wildcard for zero or more characters

See also: timespec, parsetimewin, read_data
""" read_hdf5!
function read_hdf5!(S::GphysData, filestr::String, s::TimeSpec, t::TimeSpec;
  fmt ::String                = "asdf",                 # data format
  id  ::Union{String, Regex}  = "*",                    # id string
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
function read_hdf5(filestr::String, s::TimeSpec, t::TimeSpec;
  fmt ::String                = "asdf",                 # data format
  id  ::Union{String, Regex}  = "*",                    # id string
  msr ::Bool                  = true,                   # read multistage response?
  v   ::Int64                 = KW.v                    # verbosity
  )

  S = SeisData()
  read_hdf5!(S, filestr, s, t,
    fmt     = fmt,
    id      = id,
    msr     = msr,
    v       = v
    )
  return S
end
