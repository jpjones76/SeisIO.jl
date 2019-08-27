function flush_suds!(S::GphysData,
  xc::Array{UnitRange{Int64},1},
  xn::Array{Int64,1},
  xt::Array{Int64,1},
  xz::Array{Int64,1},
  xj::Int64,
  v::Int64)

  (xj == 0) && return nothing

  # Post-read ================================================================
  resize!(xc, xj)
  resize!(xn, xj)
  resize!(xt, xj)
  resize!(xz, xj)

  if v > 1
    println("Done processing: ")
    println("Processed xj = ", xj, " segments")
    println("Segment ranges = ", xc)
    println("Segment starts = ", xn)
    println("Segment start times = ", xt)
    println("Channel segment lengths = ", xz)
  end

  # Determine length of each array in S.x
  Lx = zeros(Int64, S.n)
  for j = 1:xj
    nz = xz[j]
    for i in xc[j]
      Lx[i] += nz
    end
  end

  # Data assignment ==========================================================
  # Initialize arrays in S.x and counters sxi
  sxi = ones(Int64, S.n)
  for i = 1:S.n
    if isempty(S.x[i])
      S.x[i] = Array{Float32,1}(undef, Lx[i])
    else
      lxi = length(S.x[i])
      sxi[i] = lxi + 1
      resize!(S.x[i], lxi + Lx[i])
    end
  end

  # Loop again over xn; this time, copy each segment over
  for j = 1:xj
    xs = xn[j]
    si = xs
    for i in xc[j]
      t0 = xt[j]
      nz = xz[j]
      copyto!(S.x[i], sxi[i], BUF.x, si, nz)
      si += nz
      sxi[i] += nz

      # determine start time of channel
      if isempty(S.t[i])
        S.t[i] = Int64[1 t0; nz 0]
      else
        check_for_gap!(S, i, t0, nz, v)
      end
    end
  end
  return nothing
end
