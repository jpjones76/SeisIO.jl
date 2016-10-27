using DSP:filt, hilbert
using Distributions
using SeisIO
#using HistUtils: gdm, qchd
#export seispol, seisvpol, polhist, polexpand

# Pass in a SeisEvent struct
function s_orient(S::SeisEvent)

  # Fill gaps
  ungap!(S.data)

  # Generate list of seismic inst. IDs with all but the channel codes
  iid = Array{String,1}()
  cnt = Array{Array{Int64,1},1}()
  Θ_r = Array{Float64,1}()
  for i = 1:1:S.data.n
    id = S.data.id[i][1:end-1]
    if id[end] in ['G', 'H', 'L', 'M', 'N', 'P']
      j = find(iid.==id)
      if isempty(j)
        push!(iid, id)
        push!(cnt, [i])
      else
        push!(cnt[j], i)
      end
      cmp = S.data.id[i][end]
      if cmp in ['N', '1']
        Θ_r[i] = S.data.loc[i][4]
      end
    end
  end

  # For each iid, form a matrix X from Z, N, E or Z, 1, 2
  L = length(iid)
  Θ_c = zeros(Float64, L)
  Σ_c = zeros(Float64, L)
  for i = 1:1:L
    # Three shall be the number of thy counting, and ...
    if length(cnt[i]) == 3
      M_src = rot2d(S.data.misc["baz"][i])
      X = [S.data.x[cnt[i][1]] S.data.x[cnt[i][2]]]*M_src
      if !isapprox(Θ_r[i], 0.0)
        X = X*rot2d(Θ_r[i])
      end
      (P, W) = seispol([S.data.x[cnt[i][3]] X])
      d = fit_mle(Normal, P["az"], W["az"])
      Θ_c[i] = d.μ
      Σ_c[i] = d.σ
    end
  end
  return (Θ_c, Σ_c)
end

"""
**P**, **W** = seispol(**X**; **av** = true, **Na** = 13, **z** = 1.0:1.0:180.0)


Polarization analysis of X, returning attributes from Vidale (1986) and Jurkevics (1988).

    INPUT   MEANING
    X       Seismic data, with +Z indicating downward motion.
            Arrange column vectors as [Z_1 N_1 E_1 ... Z_K N_K E_K].
    av      Time-average X when computing θ, η, φ?
    Na      Width of moving average filter (Samples)
    z       Phase angles ψ (°)

    OUTPUTS

    P       Dictionary with polarization information.
    W       Corresponding weights

    STR     MEANING                RANGE
    az      Azimuth           -90° ≤ θ ≤ +90°
    el      Ellipticity          0 ≤ η ≤ 1
    in      Incidence angle      0°≤ φ ≤ 90°
    pl      Planarity            0 ≤ ν ≤ 1
    rc      Rectilinearity       0 ≤ ρ ≤ 1

NOTES


(a)   Azimuth is measured *CLOCKWISE FROM NORTH*; thus +30 = N30°E,
-30 = N30°W, etc. This has the same sense as strike; many polarization
papers use a coordinate system with azimuth taken anticlockwise from East.

(b)   Incidence is measured from vertical. This sense matches Jurkevics (1988),
but is the complement of the "dip" parameter defined in Vidale (1986).

"""
#Author: Joshua Jones, highly.creative.pseudonym@gmail.com
#Version: 1.1, 2016-1-16

function seispol{T}(X::AbstractMatrix{T};
                    z = collect(1.0:1.0:180.0)::Array{Float64,1},
                    Na = 13::Int,
                    av = true::Bool)
  Nx, Nc = size(X)
  rem(Nc,3)!=0 && error("3C data required!")          # Ensure X is 3-component data
  Nk = round(Int,Nc/3)
  Na = minimum([Na round(Int, Nx/4)])                 # Filter order
  if isreal(X)
    X = hilbert(X)                                    # Ensure we have an analytic signal
  end

  b = vec(convert(T,1/Na).*ones(T,1,Na))
  z = convert(Array{T,1},collect(z))
  W1 = zeros(T,Nx,Nk)
  if av
    W2 = W1
  else
    W2 = copy(W1)
  end
  P = Dict{ASCIIString,AbstractArray{T}}("az" => copy(W1),
                                          "el" => copy(W1),
                                          "in" => copy(W1),
                                          "pl" => copy(W1),
                                          "rc" => copy(W1))
  V1 = complex(zeros(T,3,Nx))
  U = zeros(T,3,Nx)

  for k = 1:1:Nk
    x = X[:,3*k-2:3*k]
    C = cat(2, x[:,1].*conj(x[:,1]), x[:,1].*conj(x[:,2]), x[:,1].*conj(x[:,3]),
               x[:,2].*conj(x[:,1]), x[:,2].*conj(x[:,2]), x[:,2].*conj(x[:,3]),
               x[:,3].*conj(x[:,1]), x[:,3].*conj(x[:,2]), x[:,3].*conj(x[:,3]))
    C = circshift(filt(b, one(T), C),[-floor(Int, Na/2) 0])

    # Jurkevics attributes
    for m = 1:1:Nx
      c = cat(1, C[m,1:3], C[m,4:6], C[m,7:9])
      u,V = eig(c, scale=false, permute=false)
      i = sortperm(u, rev=true)
      if av
        V1[:,m] = V[:,i[1]]
      end
      U[:,m] = u[i]
      W2[m,k] = sum(diag(c).^2)
    end
    P["rc"][:,k] = (1.0 .- ( (U[2,:] .+ U[3,:]) ./ (2.0.*U[1,:]) ))'
    P["pl"][:,k] = (1.0 .- ( 2.0.*U[3,:] ./ (U[1,:].+U[2,:]) ))'

    # Vidale attributes
    if !av
      V1 = [x[:,1]./x[:,3] x[:,2]./x[:,3] ones(T,Nx,1)]'
      V1 = V1./repmat(sqrt(sum(V1.*conj(V1),1)),3,1)
      W1[:,k] = sum(abs(x).^2,2)
    end
    P["az"][:,k], P["el"][:,k], P["in"][:,k] = seisvpol(V1, z)
  end

  # Truncate
  P["az"] = P["az"][1:Nx-Na,:]
  P["el"] = P["el"][1:Nx-Na,:]
  P["in"] = P["in"][1:Nx-Na,:]
  P["pl"] = P["pl"][1:Nx-Na,:]
  P["rc"] = P["rc"][1:Nx-Na,:]
  W = Dict{ASCIIString,AbstractArray{T}}("az" => W1[1:Nx-Na,:],
                                         "el" => W1[1:Nx-Na,:],
                                         "in" => W1[1:Nx-Na,:],
                                         "pl" => W2[1:Nx-Na,:],
                                         "rc" => W2[1:Nx-Na,:])
  return (P, W)
end

function seisvpol{T}(V1::AbstractMatrix{T}, z)
  cis = cosd(z) .+ im.*sind(z)
  M = .+(real(cis*V1[1,:]).^2,real(cis*V1[2,:]).^2,real(cis*V1[3,:]).^2)
  N = size(M,1)
  xr,ir = findmax(M,1)
  ir = mod(ir.-1,N).+1
  Xr = real(V1 .* repmat(cis[ir],3,1))
  η = real(sqrt((1.-xr)./xr))'
  θ = atand( Xr[3,:] ./ Xr[2,:] )
  φ = abs(atand(sqrt(Xr[2,:].^2 .+ Xr[3,:].^2) ./ Xr[1,:]))
  return θ, η, φ
end

function polhist{K,T}(P::Dict{K,T}, W::Dict;
                      ts = false::Bool,
                      hd = false::Bool,
                      L = 100::Int,
                      La = 20::Int,
                      N = 100::Int)
  # Rescale
  if haskey(P,"az")
    P["az"] = (P["az"]/180.0) + 0.5
  end
  if haskey(P,"in")
    P["in"]/=90.0
  end

  # Constants
  τ = ceil(Int, N/4)
  F = collect(keys(P))
  p0 = P[F[1]]
  t0 = eltype(p0)
  Np = size(F,1)
  if ndims(p0) == 2
    Nx, Nk = size(p0)
  else
    Nx, ~, Nk = size(p0)
  end
  Npk  = Np*Nk
  tt   = 1 + (0:La:Nx-L)
  Nt   = size(tt,1)
  dp   = 1/N
  x0   = collect(0:dp:1-dp)
  x1   = cat(1, x0[2:end], 1)
  rx0  = Array{t0}(1, N, Nk)
  rx1  = copy(rx0)
  rx0[:,1:N,1:Nk] = repmat(x0, 1, Nk)
  rx1[:,1:N,1:Nk] = repmat(x1, 1, Nk)

  H = Dict{K,T}()
  if hd && ts
    D = zeros(t0, 2*Npk+Np, Nt)
  elseif hd
    D = zeros(t0, 2*Npk, Nk)
  end

  polexpand(P,W)
  for p in F
    WW = zeros(t0,Nx, N, Nk)
    for n = 1:1:N
      WW[:,n,1:Nk] = W[p]
    end
    if hd
      if p == "az"
        c = true
      else
        c = false
      end
      G = gdm(N, τ, c=c, F="gauss")
    end
    if ts
      j = 0
      for t = 0:La:Nx-L
        j = j+1
        H[p][:,:,j] = squeeze(sum(repmat(W[p](t+1:t+L,:,:),[1 N 1]) .*
                                  broadcast(>,P[p][t+1:t+L,:,:],rx0) .*
                                  broadcast(<=,P[p][t+1:t+L,:,:],rx1),1))
        if hd && (t >= La)
          d1 = qchd(squeeze(reshape(H[p][:,:,[j-1 j]],(N, 2*Nk, 1))), G=G)

          # Obtain D_t
          D[1 + (p-1)*Nk : p*Nk, j] = diag(d1[Nk+1:end,1:Nk])

          # Obtain average D_k for k1 != k
          du = d1[1:Nk, 1:Nk]
          D[1+Npk+(p-1)*Nk : Npk+p*Nk, j-1] = sum(du,2)./(Nk-1)
        end
      end
    else
      H[p] = squeeze(sum(WW .* broadcast(>,P[p],rx0) .* broadcast(<=,P[p],rx1),1),1)
      H[p][isnan(H[p])] = 0
      if hd
        D[1+Npk+(p-1)*Nk : Npk+p*Nk, :] = qchd(H[p], G)
      end
    end
    P[p]=squeeze(P[p],2)
    W[p]=squeeze(W[p],2)
  end
  if haskey(P,"az")
    P["az"] = (P["az"]-0.5)*180.0
  end
  if haskey(P,"in")
    P["in"]*=90.0
  end

  if hd
    return H, D
  else
    return H
  end
end

function polexpand{K,T}(P::Dict{T,K}, W::Dict)
  for i in collect(keys(P))
    if ndims(P[i]) == 2
      Nx, Nk = size(P[i])
      P2 = zeros(eltype(P[i]), (Nx, 1, Nk))
      W2 = copy(P2)
      for k = 1:1:Nk
        P2[:,1,k] = copy(P[i][:,k])
        W2[:,1,k] = copy(W[i][:,k])
      end
      P[i] = copy(P2)
      W[i] = copy(W2)
    end
  end
end


# Note that I'm using (M*X')' = X*M' above, → this is M' from IRIS' formula
# Keeping X as a two-column matrix should be much faster.
rot2d(ϕ) = [cosd(ϕ) -sind(ϕ); sind(ϕ) cosd(ϕ)]
