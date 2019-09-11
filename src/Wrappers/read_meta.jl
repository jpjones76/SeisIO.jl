export read_meta, read_meta!

@doc """
    read_meta

Generic wrapper for reading metadata (i.e., instrument parameters, responses).

    S = read_meta(fmt, filestr [, keywords])

Read metadata in file format `fmt` matching file pattern `filestr` into a new
SeisData object `S`.

    read_meta!(S, fmt, filestr [, keywords])

Read metadata in file format `fmt` matching file pattern `filestr` into existing
SeisData object `S`.

### Supported File Formats
| Format                    | String          |
| :---                      | :---            |
| Dataless SEED             | dataless        |
| FDSN Station XML          | sxml            |
| SACPZ                     | sacpz           |
| SEED RESP                 | resp            |

### Keywords
|KW      | Used By  | Type      | Default   | Meaning                         |
|:---    |:---      |:---       |:---       |:---                             |
| msr    | sxml     | Bool      | false     | read full MultiStageResp?       |
| s      | all      | TimeSpec  |           | Start time                      |
| t      | all      | TimeSpec  |           | Termination (end) time          |
| units  | resp     | Bool      | false     | fill in MultiStageResp units?   |
|        | dataless |           |           |                                 |
| v      | all      | Int64     | 0         | verbosity                       |

### Notes
1. Unlike `read_data`, `read_meta` can't use `guess` for files of unknown type.
The reason is that most metadata formats are ASCII-based; generally only XML
files have reliable tests for uniqueness.

See also: SeisIO.KW, get_data, read_data
""" read_meta!
function read_meta!(S::GphysData, fmt::String, filestr::String;
  msr     ::Bool      = false                     ,  # read as MultiStageResp?
  s       ::TimeSpec  = "0001-01-01T00:00:00"     ,  # Start
  t       ::TimeSpec  = "9999-12-31T12:59:59"     ,  # End or Length (s)
  units   ::Bool      = false                     ,  # fill in units of CoeffResp stages?
  v       ::Int64     = KW.v                      ,  # verbosity level
  )

  one_file = safe_isfile(filestr)

  if fmt == "dataless"
    if one_file
      append!(S, read_dataless(filestr, s=s, t=t, v=v, units=units))
    else
      files = ls(filestr)
      for fname in files
        append!(S, read_dataless(fname, s=s, t=t, v=v, units=units))
      end
    end

  elseif fmt == "resp"
    read_seed_resp!(S, filestr, units=units)

  elseif fmt == "sacpz"
    if one_file
      read_sacpz!(S, filestr)
    else
      files = ls(filestr)
      for fname in files
        read_sacpz!(S, fname)
      end
    end

  elseif fmt == "sxml"
    if one_file
      append!(S, read_sxml(filestr, s=s, t=t, v=v, msr=msr))
    else
      files = ls(filestr)
      for fname in files
        append!(S, read_sxml(fname, s=s, t=t, v=v, msr=msr))
      end
    end

  else
    error("Unknown file format!")
  end

  return nothing
end

@doc (@doc read_meta!)
function read_meta(fmt::String, filestr::String;
  msr     ::Bool      = false                     ,  # read as MultiStageResp?
  s       ::TimeSpec  = "0001-01-01T00:00:00"     ,  # Start
  t       ::TimeSpec  = "9999-12-31T12:59:59"     ,  # End or Length (s)
  units   ::Bool      = false                     ,  # fill in units of CoeffResp stages?
  v       ::Int64     = KW.v                      ,  # verbosity level
  )

  S = SeisData()
  read_meta!(S, fmt, filestr, msr=msr, s=s, t=t, units=units, v=v)
  return S
end
