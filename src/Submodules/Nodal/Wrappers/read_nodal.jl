@doc """
    S = read_nodal(filestr [, keywords])

Read nodal data from file `filestr` into new NodalData object `S`.

## Keywords
|KW     | Type      | Default               | Meaning                   |
|:---   |:---       |:---                   |:---                       |
| ch_s  | Int64     | 1                     | first channel index       |
| ch_e  | Int64     | (last channel)        | last channel index        |
| fmt   | String    | "silixa"              | nodal data format         |
| nn    | String    | ""                    | network name in `:id`     |
| s     | TimeSpec  | "0001-01-01T00:00:00" | start time [^1]           |
| t     | TimeSpec  | "9999-12-31T12:59:59" | end time                  |
| v     | Integer   | 0                     | verbosity                 |

[^1] Special behavior: Real values supplied to `s=` and `t=` are treated as seconds *from file begin*; most SeisIO functions treat reals as seconds relative to current time.

See also: `TimeSpec`, `parsetimewin`, `read_data`
""" read_nodal
function read_nodal(fstr::String;
  ch_s    ::Int64     = one(Int64)                , # starting channel number
  ch_e    ::Int64     = Int64(2147483647)         , # ending channel number
  fmt     ::String    = "silixa"                  , # nodal data format
  memmap  ::Bool      = false                     , # use mmap? (DANGEROUS)
  nn      ::String    = ""                        , # network name
  s       ::TimeSpec  = "0001-01-01T00:00:00"     , # Start
  t       ::TimeSpec  = "9999-12-31T12:59:59"     , # End or Length (s)
  v       ::Integer   = KW.v                      , # verbosity
  )

  if fmt == "silixa"
    S = read_tdms(fstr, nn, s, t, ch_s, ch_e, memmap, v)
  else
    error("Unrecognized format String!")
  end
  return S
end
