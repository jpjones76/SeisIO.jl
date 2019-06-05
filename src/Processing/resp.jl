export fctopz, equalize_resp!, equalize_resp

function resp_f(z::Array{Complex{T},1}, p::Array{Complex{T},1}, g::T, h::T, f::Array{T,1}, fs::T) where T <: Real
  zp = ZeroPoleGain(pushfirst!(copy(z), Complex{T}(2.0)), pushfirst!(copy(p), Complex{T}(2.0)), g)
  pr = convert(PolynomialRatio, zp)
  return h*freqs(pr, f, fs)
end

"""
    resp = fctopz(fc)

Convert critical frequency fc to a matrix of complex poles and zeros. zeros are in resp[:,1], poles in resp[:,2].
"""
function fctopz(f::T, c::T) where T <: AbstractFloat
  fxp = T(2.0*pi)*f
  r = sqrt(Complex(c^2 - one(T)))
  p = zeros(Complex{T}, 1)
  z = Complex{T}[r-c, -c-r].*fxp
  return p, z
end

function translate_resp!( X::Array{T,1},
                          fs::T,
                          Ro::Union{PZResp,PZResp64},
                          Rn::Union{PZResp,PZResp64}) where T <: Real

  Nx = length(X)
  N2 = nextpow(2, Nx)
  f = T[collect(zero(T):one(T):T(N2)/T(2.0)); collect(T(-N2)/T(2.0)+one(T):one(T):-one(T))]           # Frequencies
  f[1] = eps(T)
  rmul!(f, T(fs/N2))
  F0 =  resp_f(Ro.z, Ro.z, Ro.c, one(T), f, fs)                           # Old resp
  F1 =  resp_f(Rn.z, Rn.p, Rn.c, one(T), f, fs)                           # New resp
  xf = fft([X; zeros(T, N2-Nx)])                                          # FFT
  rf = map(Complex{T}, (F1.*conj(F0) ./ (F0.*conj(F0).+eps(T))))
  X[:] = real(ifft(xf.*rf))[1:Nx]
  return nothing
end

function check_resp_type(R::Union{PZResp,PZResp64}, T::Type)
  if typeof(getfield(R, :c)) == T
    return R
  elseif T == Float64
    return PZResp64(T.(R.c), Complex{T}.(R.p), Complex{T}.(R.z))
  else
    return PZResp(T.(R.c), Complex{T}.(R.p), Complex{T}.(R.z))
  end
end

@doc """
    equalize_resp!(S::GphysData, resp_new:ZPGain)

Translate all data in S.x to instrument response resp_new.

    equalize_resp!(S, resp_new[, c_new=hᵪ, C=C])

As above, but specify c_new as a KW and only operate on channel numbers C.

    equalize_resp(S, resp_new[, c_new=hᵪ, C=C])

"Safe" translation of frequency responses of channels S[C], output to a new
SeisData object.

""" equalize_resp!
function equalize_resp!(S::GphysData, R_new::Union{PZResp,PZResp64};
                        C::Array{Int64,1} = Int64[]
                        )

  if isempty(C)
    C = collect(1:S.n)
  end

  RESP = getfield(S, :resp)
  FS = getfield(S, :fs)
  X = getfield(S, :x)
  for i in C
    fs = getindex(FS, i)
    fs == 0.0 && continue

    x = getindex(X, i)
    T = eltype(x)
    R = getindex(RESP, i)

    # Check resp types
    Ro = check_resp_type(R, T)
    Rn = check_resp_type(R_new, T)

    if Ro != Rn
      # Check fs
      if typeof(fs) != T
        fs = T.(fs)
      end

      translate_resp!(x, fs, Ro, Rn)
      setindex!(RESP, Rn, i)
      note!(S, i, string( "equalize_resp!, changed :resp. Old response: ",
                          repr("text/plain", R, context=:compact=>true) ) )
    end
  end
  return nothing
end
@doc (@doc equalize_resp!)
function equalize_resp(S::GphysData, R_new::Union{PZResp,PZResp64}; C::Array{Int64,1} = Int64[])
  U = deepcopy(S)
  equalize_resp!(U, R_new, C=C)
  return U
end

# Seischannel methods
function equalize_resp!(Ch::GphysChannel, R_new::Union{PZResp,PZResp64})
  fs = getfield(Ch, :fs)
  fs == 0.0 && return nothing

  # Check resp types
  R = getfield(Ch, :resp)
  x = getfield(Ch, :x)
  T = eltype(x)
  Ro = check_resp_type(R, T)
  Rn = check_resp_type(R_new, T)

  if Ro != Rn
    # Check fs
    if typeof(fs) != T
      fs = T.(fs)
    end

    translate_resp!(x, fs, Ro, Rn)
    setfield!(Ch, :resp, Rn)
    setfield!(Ch, :x, x)
    note!(Ch, string( "equalize_resp!, changed :resp. Old response: ",
                    repr("text/plain", R, context=:compact=>true) ) )
  end
  return nothing
end
function equalize_resp(Ch::GphysChannel, R_new::Union{PZResp,PZResp64})
  U = deepcopy(Ch)
  equalize_resp!(U, R_new)
  return U
end
