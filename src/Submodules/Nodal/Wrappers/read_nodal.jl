@doc """
    S = read_nodal(fmt, filestr [, keywords])

Read nodal data from file `filestr` into new NodalData object `S`.

## Keywords
|KW     | Type      | Default   | Used By   | Meaning                         |
|:---   |:---       |:---       |:---       |:---                             |
| ch_s  | Int64     | 1         | all       | first channel index             |
| ch_e  | Int64     |           | all       | last channel index              |
| nn    | String    | "N0"      | all       | network name in `:id`           |
| s     | TimeSpec  |           | silixa    | start time [^1]                 |
| t     | TimeSpec  |           | silixa    | end time                        |
| v     | Integer   | 0         | silixa    | verbosity                       |

[^1] Special behavior: Real values supplied to `s=` and `t=` are treated as seconds *from file begin*; most SeisIO functions treat Real as seconds relative to current time.

See also: `TimeSpec`, `parsetimewin`, `read_data`
""" read_nodal
function read_nodal(fmt::String, fstr::String;
  ch_s    ::Int64     = one(Int64)                , # starting channel number
  ch_e    ::Int64     = Int64(2147483647)         , # ending channel number
  memmap  ::Bool      = false                     , # use mmap? (DANGEROUS)
  nn      ::String    = "N0"                      , # network name
  s       ::TimeSpec  = "0001-01-01T00:00:00"     , # Start
  t       ::TimeSpec  = "9999-12-31T12:59:59"     , # End or Length (s)
  v       ::Integer   = KW.v                      , # verbosity
  )

  if fmt == "silixa"
    S = read_silixa_tdms(fstr, nn, s, t, ch_s, ch_e, memmap, v)
  elseif fmt == "segy"
    S = read_nodal_segy(fstr, nn, s, t, ch_s, ch_e, memmap)
  else
    error("Unrecognized format String!")
  end
  return S
end
