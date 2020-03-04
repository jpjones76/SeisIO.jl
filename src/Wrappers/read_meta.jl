export read_meta, read_meta!

@doc """
    S = read_meta(fmt, filestr [, keywords])
    read_meta!(S, fmt, filestr [, keywords])

Generic wrapper for reading channel metadata (i.e., instrument parameters, responses). Reads metadata in file format `fmt` matching file pattern `filestr` into `S`.

This function is fully described in the official documentation at https://seisio.readthedocs.io/ under subheading **Metadata Files**.

See also: `SeisIO.KW`, `get_data`, `read_data`
""" read_meta!
function read_meta!(S::GphysData, fmt::String, fpat::Union{String, Array{String,1}};
  memmap  ::Bool      = false                     ,  # use Mmap.mmap? (unsafe)
  msr     ::Bool      = false                     ,  # read as MultiStageResp?
  s       ::TimeSpec  = "0001-01-01T00:00:00"     ,  # Start
  t       ::TimeSpec  = "9999-12-31T12:59:59"     ,  # End or Length (s)
  units   ::Bool      = false                     ,  # fill in units of CoeffResp stages?
  v       ::Integer   = KW.v                      ,  # verbosity level
  )

  N = S.n
  files = Array{String, 1}(undef, 0)
  hashes = zeros(UInt64, S.n)
  fpat_is_array = isa(fpat, Array{String, 1})
  opts = string("msr=", msr,  ", ",
                "s=\"", s,  "\", ",
                "t=\"", t,  "\", ",
                "units=", units, ", ",
                "v=", KW.v, ")" )

  if fpat_is_array
    one_file = false
    for f in fpat
      ff = abspath(f)
      if safe_isfile(ff)
        push!(files, ff)
      else
        append!(files, ls(ff))
      end
    end
  else
    filestr = abspath(fpat)
    one_file = safe_isfile(filestr)
    if one_file == false
      append!(files, ls(filestr))
    else
      push!(files, filestr)
    end
  end
  isempty(files) && error("No valid files to read!")

  if fmt == "resp"
    read_seed_resp!(S, files, memmap, units)
  else
    for fname in files
      if fmt == "dataless"
        append!(S, read_dataless(fname, memmap=memmap, s=s, t=t, v=v, units=units))
      elseif fmt == "sacpz"
        read_sacpz!(S, fname, memmap=memmap)
      elseif fmt == "sxml"
        append!(S, read_sxml(fname, s, t, memmap, msr, v))
      else
        error("Unknown file format!")
      end
      track_hdr!(S, hashes, fmt, fname, opts)
    end
  end
  return nothing
end

@doc (@doc read_meta!)
function read_meta(fmt::String, fpat::Union{String, Array{String,1}};
  memmap  ::Bool      = true                      ,  # use Mmap.mmap? (unsafe)
  msr     ::Bool      = false                     ,  # read as MultiStageResp?
  s       ::TimeSpec  = "0001-01-01T00:00:00"     ,  # Start
  t       ::TimeSpec  = "9999-12-31T12:59:59"     ,  # End or Length (s)
  units   ::Bool      = false                     ,  # fill in units of CoeffResp stages?
  v       ::Integer   = KW.v                      ,  # verbosity level
  )

  S = SeisData()
  read_meta!(S, fmt, fpat, memmap=memmap, msr=msr, s=s, t=t, units=units, v=v)
  return S
end
