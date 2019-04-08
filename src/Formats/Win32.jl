using DelimitedFiles: readdlm
export readwin32, readwin32!

# =======================================================
# Auxiliary functions not for export

function findhex(hexID::UInt16, hexIDs::Array{UInt16,1})
  for d=1:length(hexIDs)
    if hexIDs[d]==hexID
      return d
    end
  end
  return -1
end

function add_win32!(S::SeisData, cinfo::String)
  c = String.(split(cinfo))
  n = S.n
  S.name[n] = length(c) > 18 ? String(c[19]) : ""
  S.loc[n] = Float64[parse(Float64, c[14]),
                     parse(Float64, c[15]),
                     parse(Float64, c[16]),
                     0.0, 0.0]
  S.units[n] = String(c[9])
  S.gain[n] = parse(Float32, c[13]) /
              (parse(Float32, c[8]) * 10.0f0^(parse(Float32, c[12])/20.0f0))



  S.misc[n]["lineDelay"] = parse(Float32,c[3]) / 1000.0f0
  S.misc[n]["fc"] = 1.0f0 / parse(Float32, c[10])
  S.misc[n]["hc"] = parse(Float32,  c[11])
  S.misc[n]["pCorr"] = parse(Float32, c[17])
  S.misc[n]["sCorr"] = parse(Float32, c[18])
  return nothing
end

"""
    S = readwin32(filestr, chanfile)

Read all win32 files matching pattern `filestr` into SeisData object `S`, with channel info stored in `chanfile`.
"""
function readwin32(filestr::String, cf::String; v::Int=KW.v, jst::Bool=true)

  # Parse chans file
  Chans = readlines(cf)
  L = length(Chans)
  hexIDs = Array{UInt16,1}(undef, 0)
  chanIDs = Array{String,1}(undef ,0)
  bads = falses(L)
  for m = 1:L
    if occursin(r"^\s*(?:#|$)", Chans[m])
      bads[m] = true
      continue
    end
    cline = split(Chans[m])
    push!(hexIDs, reinterpret(UInt16, hex2bytes(cline[1]))[1])
    push!(chanIDs, join(cline[4:5],'.'))
  end
  deleteat!(Chans, bads)

  files = ls(filestr)
  nf = length(files)

  S = SeisData()

  # Some constants
  B::UInt16 = 0x0000
  C::UInt8 = 0x00
  N::UInt16 = 0x0000
  Nh::Int64 = 0
  V::UInt16 = 0x0000
  c::Int64 = 0
  gap::Int64 = 0
  hexID::UInt16 = 0x0000
  i4::Int8 = 0x00
  k::Int64 = 0
  n::Int64 = 0
  netID::UInt8 = 0x00
  orgID::UInt8 = 0x00
  t_new::Int64 = 0
  t_old::Int64 = 0
  τ::UInt32 = 0x00000000

  datehex::Array{UInt8,1} = Array{UInt8,1}(undef, 8)
  # U::Array{UInt8,1} = zeros(UInt8, 4)
  x::Array{Int32,1} = zeros(Int32, 100)

  # Preallocated arrays
  sums      = Array{Int64,1}(undef, 0)
  gapStart  = Array{Array{Int64,1},1}(undef, 0)
  gapEnd    = Array{Array{Int64,1},1}(undef, 0)
  seisN     = Array{Int64,1}(undef, 0)
  OldTime   = Array{Int64,1}(undef, 0)
  orgIDs    = Array{UInt8,1}(undef, 0)
  netIDs    = Array{UInt8,1}(undef, 0)
  seenIDs   = Array{UInt16,1}(undef, 0)
  xi        = Array{Int64,1}(undef, 0)
  data      = Array{Array{Int32,1},1}(undef, 0)
  buf       = Array{UInt8,1}(undef, 1024)

  @inbounds for fname in files
    v>0 && println("Processing ", fname)
    open(fname, "r") do fid
      seek(fid, 4)
      while !eof(fid)
        # Start time: matches file info despite migraine-inducing nesting
        read!(fid, datehex)
        stime = DateTime(bytes2hex(datehex), "yyyymmddHHMMSSsss")
        t_new = stime.instant.periods.value
        skip(fid, 4)
        lsecb = ntoh(read(fid, UInt32))
        τ = 0x00000000

        while τ < lsecb
          orgID = read(fid, UInt8)
          netID = read(fid, UInt8)
          hexID = read(fid, UInt16)
          k = findhex(hexID, seenIDs)
          V = ntoh(read(fid, UInt16))
          C = UInt8(V >> 12)
          N = V & 0x0fff
          Nh = Int64(N)

          # Increment bytes read (this file), decrement N if not 4-bit
          if C == 0x00
            B = div(N,0x0002)
          else
            N -= 0x0001
            B = UInt16(C)*N
          end
          τ += (0x0000000a + UInt32(B))

          if k < 0
            nx = 60*Nh*nf
            ts = (t_new-dtconst)*1000 - (jst == true ? 32400000000 : 0)

            c = findhex(hexID, hexIDs)
            id = chanIDs[c]
            push!(S, SeisChannel())
            add_win32!(S, Chans[c])
            j = S.n
            S.id[j] = id
            S.fs[j] = Float64(Nh)
            S.t[j] = [1 ts; nx 0]
            S.misc[j] = Dict{String,Any}("orgID" => orgID, "netID" => netID,
              "hexID" => hexID,
              "locID" => bytes2hex([orgID & 0xff | (netID << 4) & 0xf0])
              )
            push!(sums, 0)
            push!(gapStart, Array{Int64,1}(undef, 0))
            push!(gapEnd, Array{Int64,1}(undef, 0))
            push!(seisN, 0)
            push!(OldTime, 0)
            push!(orgIDs, orgID)
            push!(netIDs, netID)
            push!(seenIDs, hexID)
            push!(data, Array{Int32,1}(undef, nx))
            push!(xi, 0)
            k = length(xi)
            S.misc[j]["k"] = k
          end
          t_old = getindex(OldTime, k)
          x[1] = ntoh(read(fid, Int32))

          if C == 0x00
            n = 2
            for i = 0x0001:B
              i4 = read(fid, Int8)
              x1 = i4 >> 4
              x2 = (i4 << 4) >> 4
              x[n] = Int32(x1)
              if i < B
                x[n+1] = Int32(x2)
                n += 2
              end
            end

          elseif C == 0x01
            readbytes!(fid, buf, N)
            for i = 1:N
              x[i+1] = signed(buf[i])
            end

          elseif C == 0x03
            readbytes!(fid, buf, 3*N)
            for i = 1:N
              y  = UInt32(buf[3*i-2]) << 24
              y |= UInt32(buf[3*i-1]) << 16
              y |= UInt32(buf[3*i]) << 8
              x[i+1] = signed(y) >> 8
            end

          else
            fmt = (C == 0x02 ? Int16 : Int32)
            sz = sizeof(fmt)
            readbytes!(fid, buf, sz*N)
            if C == 0x04
              for i = 1:N
                y  = UInt32(buf[4*i-3]) << 24
                y |= UInt32(buf[4*i-2]) << 16
                y |= UInt32(buf[4*i-1]) << 8
                y |= UInt32(buf[4*i])
                x[i+1] = signed(y)
              end
            else
              for i = 1:N
                y  = UInt16(buf[2*i-1]) << 8
                y |= UInt16(buf[2*i])
                x[i+1] = signed(y)
              end
            end
          end
          cumsum!(x,x)
          @inbounds for jj = 1:Nh
            sums[k] += x[jj]
          end

          # Account for time gaps
          gap = t_new - t_old
          if (gap > 1000) && (t_old > 0)
            gl = (gap - 1000)/1000
            if v > 0
              @warn(@sprintf("Time gap detected! (channel %s, length %.1f s, begin %s)",
                              hexID, gl, u2d((t_old - dtconst)/1000)))
            end
            P = Nh*gl
            push!(gapStart[k], xi[k] + 1)
            push!(gapEnd[k], xi[k] + P)
            xi[k] += P
          end

          # update seis[id]
          setindex!(OldTime, t_new, k)
          unsafe_copyto!(data[k], xi[k]+1, x, 1, Nh)
          seisN[k] += Nh
          xi[k] += Nh
        end
      end
      close(fid)
    end
  end

  # Post-process
  @inbounds for ii = 1:S.n
    haskey(S.misc[ii], "k") || continue
    k = get(S.misc[ii], "k", 0)

    # Ensure we aren't overcompensating
    resize!(data[k], xi[k])

    # Get resp for passive velocity sensors
    fc = get(S.misc[ii], "fc", 1.0)
    if S.units[ii] == "m/s"
      hc = get(S.misc[ii], "hc", 1.0)
      S.resp[ii] = Complex{Float64}.(fctopz(fc, hc=hc))
    end

    # There will be issues here. Japanese files use NIED or local station
    # names, which don't necessarily use international station or network codes.
    # For an example of the (lack of) correspondence see
    # http://data.sokki.jmbsc.or.jp/cdrom/seismological/catalog/appendix/apendixe.htm
    (net, sta, chan_stub) = split(S.id[ii], '.')
    bb = getbandcode(S.fs[ii], fc = fc)    # Band code
    if chan_stub[1] == 'U'
      cc = 'Z'                            # Nope
    else
      cc = chan_stub[1]                  # Channel code
    end

    locID = get(S.misc[ii], "locID", "")
    id = net * "." * sta * "." * locID * "." * string(bb,"H",cc)

    S.id[ii] = id
    S.src[ii] = string("readwin32(", filestr, ",", cf, ")")
    S.x[ii] = Array{Float32,1}(undef, xi[k])
    map!(Float32, S.x[ii], data[k])

    # Fill gaps with mean of data
    J = length(gapStart[k])
    if J > 0
      μ = Float32(sums[k] / seisN[k])
      gs = gapStart[k]
      ge = gapEnd[k]
      for n = 1:J
        S.x[ii][gs[n]:ge[n]] .= μ
      end
    end
  end
  note!(S, string("+src: readwin32(", filestr, ",", cf, ")"))
  note!(S, string("channel file: ", cf))
  return S
end
readwin32!(S::SeisData, filestr::String, cf::String; v::Int=KW.v, jst::Bool=true) = (U = readwin32(filestr, cf, v=v, jst=jst); append!(S,U))
