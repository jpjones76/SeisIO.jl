export rseis, wseis

# SeisIO file format version changes
# 0.53  2019-09-11    removed :i, :o from CoeffResp
#                     added :i, :o to MultiStageResp
# 0.52  2019-09-03    added Types: CoeffResp, MultiStageResp
# 0.51  2019-08-01    added :f0 to PZResp, PZResp64
# 0.50  all custom types can use write(); rseis, wseis no longer required
#       String arrays and :misc are written in a completely different way
#       Type codes for :misc changed
#       deprecated BigFloat/BigInt support in :misc
#       :n is no longer stored as a UInt32
#       :x compression no longer automatic and changed from Blosc to lz4
# ======== File versions below 0.5 are no longer supported ===================
# 0.41  :loc, :resp are now custom types with their own io subroutines
#       Julia version is no longer written to file
#       (likely misidentified in file header as 0.50)
# 0.40  SeisData.id[i] no longer needs to be a length ≤ 15 ASCII string
#       files have a new file TOC field: number of channels in each record
# 0.30  SeisData.loc[i] no longer is assumed to be length 5
# 0.20  First reliable file format

const TNames = Type[  EventChannel,
                      SeisChannel,
                      EventTraceData,
                      SeisData,
                      GenLoc,
                      GeoLoc,
                      UTMLoc,
                      XYLoc,
                      GenResp,
                      PZResp64,
                      PZResp,
                      CoeffResp,
                      MultiStageResp,
                      PhaseCat,
                      SeisEvent,
                      SeisHdr,
                      SeisPha,
                      SeisSrc,
                      SourceTime,
                      EQLoc,
                      EQMag ]

const TCodes = UInt32[ 0x20474330, # " GC0"  EventChannel
                       0x20474331, # " GC1"  SeisChannel
                       0x20474430, # " GD0"  EventTraceData
                       0x20474431, # " GD1"  SeisData
                       0x20495030, # " IP0"  GenLoc
                       0x20495031, # " IP1"  GeoLoc
                       0x20495032, # " IP2"  UTMLoc
                       0x20495033, # " IP3"  XYLoc
                       0x20495230, # " IR0"  GenResp
                       0x20495231, # " IR1"  PZResp64
                       0x20495232, # " IR2"  PZResp
                       0x20495233, # " IR3"  CoeffResp
                       0x20495234, # " IR4"  MultiStageResp
                       0x20504330, # " PC0"  PhaseCat = Dict{String, SeisPha}
                       0x20534530, # " SE0"  SeisEvent
                       0x20534830, # " SH0"  SeisHdr
                       0x20535030, # " SP0"  SeisPha
                       0x20535330, # " SS0"  SeisSrc
                       0x20535430, # " ST0"  SourceTime
                       0x45514c30, # "EQL0"  EQLoc
                       0x45514d30  # "EQM0"  EQMag
                    ]

#= check:
L = length(TCodes)
u = reinterpret(UInt8, TCodes)
S = Array{String,1}(undef, L)
for i = 1:L
  S[i] = reverse(join([Char(u[4*i-3]), Char(u[4*i-2]), Char(u[4*i-1]), Char(u[4*i])]))
end

should yield the character codes in the comments above
=#


# ===========================================================================
# Auxiliary file read functions
function read_rec(io::IO, ver::Float32, c::UInt32, b::UInt64)
  i = 0
  while i < length(TCodes)
    i = i + 1
    if c == getindex(TCodes, i)
      if (ver < vSeisIO) && (c == 0x20474431)
        return read_legacy(io, ver)
      else
        return read(io, getindex(TNames, i))
      end
    end
  end
  @warn("Non-SeisIO data at byte ", position(io), "; skipped.")
  seek(io, b)
  return nothing
end

function build_file_list(patts::Union{String,Array{String,1}})
  plist = String[]
  if isa(patts, String)
    if safe_isfile(patts)
      return [patts]
    else
      plist = [patts]
    end
  else
    plist = patts
  end

  file_list = String[]
  for pat in plist
    if safe_isfile(pat)
      push!(file_list, pat)
    else
      append!(file_list, ls(pat))
    end
  end
  return file_list
end

"""
    rseis(fstr::String[, c=C::Array{Int64,1}, v=0::Int])
Read SeisIO files matching file pattern ``fstr`` into memory.
If an array of record indices is passed to keyword c, only those record indices
are read from each file.
Set v>0 to control verbosity.
"""
function rseis(patts::Union{String,Array{String,1}};
  c::Union{Int64,Array{Int64,1}}  = Int64[],
  v::Int64                        = KW.v)

  A     = []
  files = build_file_list(patts)
  sbuf  = Array{UInt8, 1}(undef, 65535)
  chans = isa(c, Int64) ? [c] : c
  ver   = vSeisIO
  L     = zero(Int64)

  nf = 0
  for f in files
    nf  = nf + 1
    io  = open(f, "r")

    # All SeisIO files begin with "SEISIO"
    if read(io, 6) != UInt8[0x53, 0x45, 0x49, 0x53, 0x49, 0x4f]
      @warn string("Skipped ", f, ": not a SeisIO file!")
      close(io)
      continue
    end

    ver = read(io, Float32)
    L   = read(io, Int64)
    C   = read!(io, Array{UInt32,1}(undef, L))
    B   = read!(io, Array{UInt64,1}(undef, L))

    # DND -- faster to avoid seek
    @inbounds if isempty(chans)
      (v > 0) && println("Reading ", L, " objects from ", f)
      (v > 1) && println("C = ", C)
      for n = 1:L
        (v > 1) && println("Reading object with code ", repr(getindex(C, n)), " (", n, "/", L, ")")
        R = read_rec(io, ver, getindex(C, n), getindex(B, n == L ? n : n+1))
        push!(A, R)
        (v > 1) && println("Read ", typeof(getindex(A, n)), " object (", n, "/", L, ")")
      end

    else
      if minimum(chans) > L
        (v > 0) && println("Skipped ", f, ": no matching record numbers.")
        close(io)
        continue
      end
      for n in chans
        if n in 1:L
          seek(io, getindex(B, n))
          R = read_rec(io, ver, getindex(C, n), getindex(B, n == L ? n : n+1))
          push!(A, R)
          (v > 1) && println("Read ", typeof(last(A)), " object from ", f, ", bytes ", getindex(B, n), ":", ((n == L) ? position(io) : getindex(B, n+1)))
        else
          (v > 0) && println(n > L ? "No" : "Skipped", " record ", n, " in ", f)
        end
      end
    end

    close(io)
  end
  (v > 0) && println("Processed ", nf, " files.")
  return A
end

"""
    wseis(fname, S)

Write SeisIO objects S to file. S can be a single object, multiple comma-delineated objects, or an array of objects.
"""
function wseis(fname::String, S...)
    L = Int64(lastindex(S))
    (L == zero(Int64)) && return nothing

    C = zeros(UInt32, L)                  # Codes
    B = zeros(UInt64, L)                  # Byte indices
    ID = Array{UInt64,1}(undef, 0)        # IDs
    TS = Array{Int64,1}(undef, 0)         # Start times
    TE = Array{Int64,1}(undef, 0)         # End times
    P  = Array{Int64,1}(undef, 0)         # Parent object indices in C, B

    # Buffer checks
    checkbuf!(BUF.int64_buf, 8)

    # open file for writing
    io = open(fname, "w")
    write(io, "SEISIO")
    write(io, vSeisIO)
    write(io, L)
    p = position(io)
    skip(io, sizeof(C) + sizeof(B))

    # Write all objects
    i = 0
    @inbounds while i < L
      i = i + 1
      setindex!(B, UInt64(position(io)), i)
      seis = getindex(S, i)
      write(io, seis)
      T = typeof(seis)

      # store type code to C
      j = 0
      while j < length(TNames)
        j = j + 1
        if T == getindex(TNames, j)
          setindex!(C, getindex(TCodes, j), i)
          break
        end
      end

      # Add to id, time index
      if T <: GphysChannel
        push!(ID, hash(getfield(seis, :id)))
        push!(P, i)
        fs = getfield(seis, :fs)
        if !isempty(seis.t)
          t = getfield(seis, :t)
          push!(TS, t[1,2])
          push!(TE, fs == zero(Float64) ? t[end,2] : sum(t, dims=1)[2] +
            round(Int64, sμ*lastindex(seis.x)/fs))
        end
      elseif T <: GphysData
        append!(ID, hash.(getfield(seis, :id)))
        append!(P, ones(Int64, seis.n).*i)
        k = 0
        ts = Array{Int64,1}(undef,seis.n)
        te = similar(ts)
        @inbounds while k < seis.n
          k = k + 1
          t = seis.t[k]
          fs = seis.fs[k]
          if !isempty(seis.t)
            setindex!(ts, t[1,2], i)
            setindex!(te, fs == zero(Float64) ? t[end,2] : sum(t, dims=1)[2] +
              round(Int64, sμ*lastindex(seis.x)/fs), i)
          end
        end
        append!(TS, ts)
        append!(TE, te)
      end
    end

    # Write TOC.
    # format: array of object types, array of byte indices
    seek(io, p)
    write(io, C)
    write(io, B)

    # File index added 2017-02-23; changed 2019-05-27
    # index format: ID hash, TS, TE, P, positions
    seekend(io)
    b = zeros(Int64, 4)
    if isempty(ID)
      fill!(b, position(io))
    else
      setindex!(b, Int64(position(io)), 1)
      write(io, ID)
      setindex!(b, Int64(position(io)), 2)
      write(io, TS)
      setindex!(b, Int64(position(io)), 3)
      write(io, TE)
      setindex!(b, Int64(position(io)), 4)
      write(io, P)
    end
    write(io, b)
    close(io)
    return nothing
end
