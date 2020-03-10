@doc """
    S = read_hdf5(filestr, s::TimeSpec, t::TimeSpec, [, keywords])
    read_hdf5!(S, filestr, s::TimeSpec, t::TimeSpec, [, keywords])

Read data in seismic HDF5 format from files matching pattern `filestr`.

`s`, `t` are required arguments but can be any Type ∈ (DateTime, Real, String);
type `?TimeSpec` for more information about how these are interpreted.

|KW     | Type      | Default   | Meaning                                     |
|:---   |:---       |:---       |:---                                         |
| id    | String    | "*"       | id pattern, formated nn.sss.ll.ccc          |
|       |           |           |  (net.sta.loc.cha); FDSN wildcards [^1]     |
| msr   | Bool      | true      | read full (MultiStageResp) instrument resp? |
| v     | Integer   | 0         | verbosity                                   |

[^1] A question mark ('?') is a wildcard for a single character; an asterisk ('*') is a wildcard for zero or more characters

See also: `TimeSpec`, `parsetimewin`, `read_data`
""" read_hdf5!
function read_hdf5!(S::GphysData, fpat::String, s::TimeSpec, t::TimeSpec;
  fmt ::String                = "asdf",                 # data format
  id  ::Union{String, Regex}  = "*",                    # id string
  msr ::Bool                  = true,                   # read multistage response?
  v   ::Integer               = KW.v                    # verbosity
  )

  N = S.n
  filestr = abspath(fpat)
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

  new_chan_src = view(S.src, N+1:S.n)
  fill!(new_chan_src, filestr)
  note!(S, N+1:S.n, string( " ¦ +source ¦ read_hdf5!(S, ",
                            "\"", fmt, "\", ",
                            "\"", s, "\", ",
                            "\"", t, "\", ",
                            "fmt=\"", fmt, "\", ",
                            "id=\"", id, "\", ",
                            "msr=", msr, ", ",
                            "v=", KW.v, ")")
        )

  return nothing
end

@doc (@doc read_hdf5!)
function read_hdf5(filestr::String, s::TimeSpec, t::TimeSpec;
  fmt ::String                = "asdf",                 # data format
  id  ::Union{String, Regex}  = "*",                    # id string
  msr ::Bool                  = true,                   # read multistage response?
  v   ::Integer               = KW.v                    # verbosity
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
