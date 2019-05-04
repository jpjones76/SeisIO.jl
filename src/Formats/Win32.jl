export readwin32, readwin32!

# =======================================================
# Auxiliary functions not for export

function findhex(hexID::UInt16, hexIDs::Array{UInt16,1})
  k = 0
  @inbounds while k < lastindex(hexIDs)
    k += 1
    if hexID == getindex(hexIDs, k)
      return k
    end
  end
  k = -1
  return k
end

function win32_cfile!( fname::String,
                        hex_bytes::Array{UInt8,1},
                        hexIDs::Array{UInt16,1},
                        S::SeisData,
                        fc::Array{Float64,1},
                        hc::Array{Float64,1},
                        nx_new::Int64
                      )

  open(fname, "r") do cf_io
    while !eof(cf_io)
      chan_line = readline(cf_io)
      occursin(r"^\s*(?:#|$)", chan_line) && continue

      # chan_info fills S
      chan_info = String.(split(chan_line))

      # Assign identifying info to placeholder arrays
      hex2bytes!(hex_bytes, chan_info[1])
      push!(hexIDs, reinterpret(UInt16, hex_bytes)[1])
      push!(fc, 1.0/parse(Float64, chan_info[10]))
      push!(hc, parse(Float64, chan_info[11]))

      # Create new channel in S from chan_info
      loc           = zeros(Float64,5)
      loc[1]        = parse(Float64, chan_info[14])
      loc[2]        = parse(Float64, chan_info[15])
      loc[3]        = parse(Float64, chan_info[16])

      C = SeisChannel()
      setfield!(C, :id, string(chan_info[4], ".", chan_info[5]))
      if length(chan_info) > 18
        setfield!(C, :name, chan_info[19])
      end
      setfield!(C, :units, chan_info[9])
      setfield!(C, :gain,  Float64(parse(Float32, chan_info[13]) /
                            (parse(Float32, chan_info[8]) *
                              10.0f0^(parse(Float32, chan_info[12]) / 20.0f0))))
      setfield!(C, :loc, loc)
      setfield!(C, :x, Array{Float32,1}(undef, nx_new))
      D = getfield(C, :misc)
      D["lineDelay"]  = parse(Float32, chan_info[3]) / 1000.0f0
      D["pCorr"]      = parse(Float32, chan_info[17])
      D["sCorr"]      = parse(Float32, chan_info[18])
      push!(S, C)
    end
  end
  return nothing
end

@doc """
    S = readwin32(dfilestr, cfilestr)

Read all win32 data files matching pattern `dfilestr` into SeisData object `S`,
with channel info stored in channel files matching pattern `cfilestr`. Both
file patterns accept wild cards.

    readwin32!(S, dfilestr, cfilestr)

As above, appending data to an existing SeisData object `S`.

!!! warning

    Using multiple channel files applies no redundancy checks of any kind.
""" readwin32
function readwin32(dfilestr::String, cfilestr::String;
                    jst::Bool=true,
                    nx_add::Int64=KW.nx_add,
                    nx_new::Int64=KW.nx_new,
                    v::Int64=KW.v
                    )
  S = SeisData()

  # Parse channel file(s)
  hex_bytes = Array{UInt8,1}(undef,2)
  hexIDs    = Array{UInt16,1}(undef, 0)
  fc        = Array{Float64,1}(undef,0)
  hc        = Array{Float64,1}(undef,0)
  if safe_isfile(cfilestr)
    win32_cfile!(cfilestr, hex_bytes, hexIDs, S, fc, hc, nx_new)
  else
    cfiles = ls(cfilestr)
    @inbounds for cfile in cfiles
      v > 1 && println("Reading channel file ", fname)
      win32_cfile!(cfile, hex_bytes, hexIDs, S, fc, hc, nx_new)
    end
  end
  L = lastindex(hexIDs)

  # Parse data files
  files = ls(dfilestr)
  nf = length(files)
  jst_const = (jst == true ? 32400000000 : 0)
  date_hex  = zeros(UInt8, 8)
  date_arr  = zeros(Int64, 6)
  checkbuf!(BUF.int32_buf, 100)
  checkbuf!(BUF.buf, 1000)
  buf       = getfield(BUF, :buf)
  x         = view(BUF.int32_buf, 1:100)

  # Preallocate arrays
  sums      = zeros(Int64, L)
  seisN     = zeros(Int64, L)
  OldTime   = zeros(Int64, L)
  locID     = Array{String,1}(undef, L)
  xi        = zeros(Int64, L)
  gapStart  = Array{Array{Int64,1},1}(undef, L)
  gapEnd    = Array{Array{Int64,1},1}(undef, L)

  @inbounds for fname in files
    v > 0 && println("Processing ", fname)
    open(fname, "r") do fid
      skip(fid, 4)
      while !eof(fid)

        # Start time
        read!(fid, date_hex)
        t_new = datehex2μs!(date_arr, date_hex)
        skip(fid, 4)

        # Bytes to read
        lsecb = Int64(ntoh(read(fid, UInt32)))
        τ = 0

        while τ < lsecb
          orgID = read(fid, UInt8)
          netID = read(fid, UInt8)
          hexID = read(fid, UInt16)
          k = findhex(hexID, hexIDs)
          V = ntoh(read(fid, UInt16))
          C = Int64(V >> 12)
          N = Int64(V & 0x0fff)
          Nh = N

          # Increment bytes read (this file), decrement N if not 4-bit
          if C == 0
            B = div(N, 2)
          else
            N -= 1
            B = C*N
          end
          τ += 10 + B
          ii = getindex(xi, k)

          # Create new channel
          if ii == 0
            nx = 60*Nh*nf
            if nx != lastindex(S.x[k])
              resize!(S.x[k], nx)
            end
            setindex!(getfield(S, :fs), Float64(Nh), k)
            t = getindex(getfield(S, :t), k)
            T = Array{Int64,2}(undef, 2, 2)
            setindex!(T, one(Int64), 1)
            setindex!(T, Int64(nx), 2)
            setindex!(T, t_new-jst_const, 3)
            setindex!(T, zero(Int64), 4)
            setindex!(getfield(S, :t), T, k)
            setindex!(gapEnd, Int64[], k)
            setindex!(gapStart, Int64[], k)
            setindex!(locID, bytes2hex([orgID & 0xff | (netID << 4) & 0xf0]), k)
            D = getindex(getfield(S, :misc), k)
            D["orgID"] = orgID
            D["netID"] = netID
            D["hexID"] = hexID
            D["locID"] = locID[k]
          end

          # Parse data
          x[1] = bswap(read(fid, Int32))
          if C == 0
            readbytes!(fid, buf, B)
            fillx_i4!(x, buf, B, 1)
          elseif C == 1
            readbytes!(fid, buf, N)
            fillx_i8!(x, buf, N, 1)
          elseif C == 2
            readbytes!(fid, buf, 2*N)
            fillx_i16_be!(x, buf, N, 1)
          elseif C == 3
            readbytes!(fid, buf, 3*N)
            fillx_i24_be!(x, buf, N, 1)
          else
            readbytes!(fid, buf, 4*N)
            fillx_i32_be!(x, buf, N, 1)
          end

          # Account for time gaps
          t_old = getindex(OldTime, k)
          gap = t_new - t_old
          if (gap > 1000000) && (t_old > 0)
            gl = div((gap - 1000000),1000000)
            (v > 0) && @warn(string("Time gap detected! (channel ", hexID, ", length ", @sprintf("%.1f",gl), "s, begin ", u2d(t_old*1.0e-6)))
            P = Nh*gl
            push!(gapStart[k], ii + 1)
            push!(gapEnd[k], ii + P)
            ii += P
            if v > 2
              println(gapStart)
              println(gapEnd)
            end
          end

          y = getindex(getfield(S, :x), k)
          xa = first(x)
          j = 1
          while j < Nh
            j += 1
            xa += getindex(x,j)
            setindex!(x, xa, j)
          end
          copyto!(y, ii+1, x, 1, Nh)

          # Update counters
          OldTime[k] = t_new
          sums[k] += x[Nh]
          seisN[k] += Nh
          xi[k] = ii + Nh
        end
      end
      close(fid)
    end
  end

  # Post-process
  src = dfilestr
  κ = findall(xi.==0)
  i = 0
  @inbounds while i < S.n
    i += 1
    i in κ && continue
    χ = getindex(S.x, i)

    # Ensure we aren't overcompensating
    lastindex(χ) == getindex(xi, i) || resize!(χ, xi[i])

    # Get resp for passive velocity sensors
    fci = getindex(fc, i)
    if S.units[i] == "m/s"
      setindex!(getfield(S, :resp), fctopz(fci, hc=getindex(hc, i)), i)
    end

    # There will be issues here. Japanese files use NIED or local station
    # names, which don't necessarily use international station or network codes.
    # For an example of the (lack of) correspondence see
    # http://data.sokki.jmbsc.or.jp/cdrom/seismological/catalog/appendix/apendixe.htm
    (net, sta, cha) = split(S.id[i], ".", limit=3, keepempty=true)
    # Band code
    bb = getbandcode(getindex(getfield(S, :fs), i), fc=fci)
    # Channel code
    cc = String(cha)[1:1]

    if cc == "U"
      cc = "Z"
      S.loc[i][5] = 180.0
    elseif cc == "N"
      S.loc[i][5] = 90.0
    elseif cc == "E"
      S.loc[i][4] = 90.0
      S.loc[i][5] = 90.0
    end
    id = string(net, ".", sta, ".", locID[i], ".", bb, "H", cc)
    setindex!(getfield(S, :id), id, i)
    setindex!(getfield(S, :src), src, i)

    # Fill gaps with mean of data
    J = length(gapStart[i])
    if J > 0
      μ = sums[i] / seisN[i]
      gs = gapStart[i]
      ge = gapEnd[i]
      n = 0
      while n < J
        n += 1
        fill!(view(χ, gs[n]:ge[n]), μ)
      end
    end
  end
  note!(S, "+src: " * src)
  note!(S, "channel file: " * cfilestr)
  if !isempty(κ)
    deleteat!(S, κ)
    v > 0 && println("Deleted ", length(κ), " empty channels after read.")
  end
  return S
end

@doc (@doc readwin32)
function readwin32!(S::SeisData, dfilestr::String, cfilestr::String;
                    jst::Bool=true,
                    nx_add::Int64=KW.nx_add,
                    nx_new::Int64=KW.nx_new,
                    v::Int64=KW.v
                    )
  U = readwin32(dfilestr, cfilestr, jst=jst, nx_add=nx_add, nx_new=nx_new)
  append!(S,U)
  return nothing
end
