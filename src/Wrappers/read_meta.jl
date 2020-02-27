export read_meta, read_meta!

# @doc """
#     S = read_meta(fmt, filestr [, keywords])
#     read_meta!(S, fmt, filestr [, keywords])
#
# Generic wrapper for reading channel metadata (i.e., instrument parameters, responses). Reads metadata in file format `fmt` matching file pattern `filestr` into `S`.
#
# ### Supported File Formats
# | Format                    | String          |
# | :---                      | :---            |
# | Dataless SEED             | dataless        |
# | FDSN Station XML          | sxml            |
# | SACPZ                     | sacpz           |
# | SEED RESP                 | resp            |
#
# ### Keywords
# |KW      | Used By  | Type      | Default   | Meaning                         |
# |:---    |:---      |:---       |:---       |:---                             |
# | memmap | *        | Bool      | false     | use mmap on files? (unsafe)     |
# | msr    | sxml     | Bool      | false     | read full MultiStageResp?       |
# | s      | *        | TimeSpec  |           | Start time                      |
# | t      | *        | TimeSpec  |           | Termination (end) time          |
# | units  | resp     | Bool      | false     | fill in MultiStageResp units?   |
# |        | dataless |           |           |                                 |
# | v      | *        | Int64     | 0         | verbosity                       |
#
# ### Notes
# 1. Unlike `read_data`, `read_meta` can't use `guess` for files of unknown type.
# The reason is that most metadata formats are ASCII-based; generally only XML
# files have reliable tests for uniqueness.
#
# See also: SeisIO.KW, get_data, read_data
# """ read_meta!
@doc """
    S = read_meta(fmt, filestr [, keywords])
    read_meta!(S, fmt, filestr [, keywords])

Generic wrapper for reading channel metadata (i.e., instrument parameters, responses). Reads metadata in file format `fmt` matching file pattern `filestr` into `S`.

This function is fully described in the official documentation at https://seisio.readthedocs.io/ under subheading **Metadata File Formats**.

See also: SeisIO.KW, get_data, read_data
""" read_meta!
function read_meta!(S::GphysData, fmt::String, filestr::String;
  memmap  ::Bool      = false                     ,  # use Mmap.mmap? (unsafe)
  msr     ::Bool      = false                     ,  # read as MultiStageResp?
  s       ::TimeSpec  = "0001-01-01T00:00:00"     ,  # Start
  t       ::TimeSpec  = "9999-12-31T12:59:59"     ,  # End or Length (s)
  units   ::Bool      = false                     ,  # fill in units of CoeffResp stages?
  v       ::Integer   = KW.v                      ,  # verbosity level
  )

  N = S.n
  one_file = safe_isfile(filestr)

  if fmt == "dataless"
    if one_file
      append!(S, read_dataless(filestr, memmap=memmap, s=s, t=t, v=v, units=units))
    else
      files = ls(filestr)
      for fname in files
        append!(S, read_dataless(fname, memmap=memmap, s=s, t=t, v=v, units=units))
      end
    end

  elseif fmt == "resp"
    read_seed_resp!(S, filestr, memmap=memmap, units=units)

  elseif fmt == "sacpz"
    if one_file
      read_sacpz!(S, filestr, memmap=memmap)
    else
      files = ls(filestr)
      for fname in files
        read_sacpz!(S, fname, memmap=memmap)
      end
    end

  elseif fmt == "sxml"
    if one_file
      append!(S, read_sxml(filestr, memmap=memmap, s=s, t=t, v=v, msr=msr))
    else
      files = ls(filestr)
      for fname in files
        append!(S, read_sxml(fname, memmap=memmap, s=s, t=t, v=v, msr=msr))
      end
    end

  else
    error("Unknown file format!")
  end

  # ===================================================================
  # logging
  note!(S, N+1:S.n, string( "+meta ¦ read_meta!(S, ",
                            "msr=", msr,  ", ",
                            "s=\"", s,  "\", ",
                            "t=\"", t,  "\", ",
                            "units=", units, ", ",
                            "v=", KW.v, ")" )
        )

  # ===================================================================
  return nothing
end

@doc (@doc read_meta!)
function read_meta(fmt::String, filestr::String;
  memmap  ::Bool      = true                      ,  # use Mmap.mmap? (unsafe)
  msr     ::Bool      = false                     ,  # read as MultiStageResp?
  s       ::TimeSpec  = "0001-01-01T00:00:00"     ,  # Start
  t       ::TimeSpec  = "9999-12-31T12:59:59"     ,  # End or Length (s)
  units   ::Bool      = false                     ,  # fill in units of CoeffResp stages?
  v       ::Integer   = KW.v                      ,  # verbosity level
  )

  S = SeisData()
  read_meta!(S, fmt, filestr, memmap=memmap, msr=msr, s=s, t=t, units=units, v=v)
  return S
end
