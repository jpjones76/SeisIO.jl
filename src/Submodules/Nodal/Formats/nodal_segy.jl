function read_nodal_segy(fname::String,
  nn::String,
  s::TimeSpec,
  t::TimeSpec,
  chans::ChanSpec,
  memmap::Bool)

  # Preprocessing
  (d0, d1) = parsetimewin(s, t)
  t0 = DateTime(d0).instant.periods.value*1000 - dtconst
  f = memmap ? IOBuffer(Mmap.mmap(fname)) : open(fname, "r")
  trace_fh = Array{Int16, 1}(undef, 3)
  shorts  = getfield(BUF, :int16_buf)
  fhd = Dict{String,Any}()
  # ww = Array{String, 1}(undef, 0)

  # ==========================================================================
  # Read file header
  fhd["filehdr"]  = fastread(f, 3200)
  fhd["jobid"]    = bswap(fastread(f, Int32))
  fhd["lineid"]   = bswap(fastread(f, Int32))
  fhd["reelid"]   = bswap(fastread(f, Int32))
  fast_readbytes!(f, BUF.buf, 48)
  fillx_i16_be!(shorts, BUF.buf, 24, 0)
  fastskip(f, 240)
  for i in 25:27
    shorts[i] = read(f, Int16)
  end
  fastskip(f, 94)

  # check endianness; can be inconsistent; 0x0400 is a kludge
  # (stands for SEG Y rev 10.24, current is rev 2.0)
  # if (unsigned(shorts[25]) > 0x0400) || (shorts[26] < zero(Int16)) || (shorts[26] > one(Int16)) || (shorts[27] < zero(Int16))
  #   shorts[25:27] .= bswap.(shorts[25:27])
  #   push!(ww, "Inconsistent file header endianness")
  # end
  # fastskip(f, 94)

  # Process
  nh = max(zero(Int16), getindex(shorts, 27))
  fhd["exthdr"] = Array{String,1}(undef, nh)
  [fhd["exthdr"][i] = fastread(f, 3200) for i in 1:nh]
  for (j,i) in enumerate(String[ "ntr", "naux", "filedt", "origdt", "filenx",
                                 "orignx", "fmt", "cdpfold", "trasort", "vsum",
                                 "swst", "swen0", "swlen", "swtyp", "tapnum",
                                 "swtapst", "swtapen", "taptyp", "corrtra", "bgainrec",
                                 "amprec", "msys", "zupdn", "vibpol", "segyver",
                                 "isfixed", "n_exthdr" ])
    fhd[i] = shorts[j]
  end

  nt = getindex(shorts, 1)
  trace_fh[1] = getindex(shorts,3)
  trace_fh[2] = getindex(shorts,5)
  trace_fh[3] = getindex(shorts,7)

  # ==========================================================================
  # initialize NodalData container; set variables
  if isempty(chans)
    chans = 1:nt
  end
  fs = sμ / Float64(trace_fh[1])
  data = Array{Float32, 2}(undef, trace_fh[2], nt)
  S = NodalData(data, fhd, chans, t0)
  net = nn * "."
  cha = string("..O", getbandcode(fs), "0")

  # ==========================================================================
  # Read traces
  j = 0

  for i = 1:nt
    C = do_trace(f, false, true, 0x00, true, trace_fh)
    if i in chans
      j += 1
      S.id[j]       = string(net, lpad(i, 5, '0'), cha)
      S.name[j]     = string(C.misc["rec_no"], "_", i)
      S.fs[j]       = C.fs
      S.gain[j]     = C.gain
      S.misc[j]     = C.misc
      S.t[j]        = C.t
      S.data[:, j] .= C.x
    end
  end

  # TO DO: actually use s, t here

  # ==========================================================================
  # Cleanup
  close(f)
  resize!(BUF.buf, 65535)
  fill!(S.fs, fs)
  fill!(S.src, realpath(fname))
  fill!(S.units, "m/m")

  # Output warnings to STDOUT
  # if !isempty(ww)
  #   for i = 1:length(ww)
  #     @warn(ww[i])
  #   end
  # end
  # S.info["Warnings"] = ww
  return S
end
