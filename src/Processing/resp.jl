export fctopz, equalize_resp!, equalize_resp

"""
    equalize_resp!(S::SeisData, resp_new::Array{Complex{Float64},2})

Translate all data in S.x to instrument response resp_new. zeros are in
resp[:,1], poles in resp[:,2]. If channel `i` has key `S.misc[i]["hc"]`, this
is used as the critical damping constant, else a value of 1.0 is assumed.

    equalize_resp!(S, resp_new[, hc_new=hᵪ, C=C])

As above, but specify hc_new as a KW and only operate on channel numbers C.

    equalize_resp(S, resp_new[, hc_new=hᵪ, C=C])

"Safe" translation of frequency responses of channels S[C], output to a new
SeisData object.

"""
function equalize_resp!(S::SeisData, resp_new::Array{Complex{Float64},2};
  hc_new=1.0/sqrt(2.0)::Float64,
  C=Int64[]::Array{Int64,1})

  pp = 2.0*Float64(pi)
  if isempty(C)
    C = 1:S.n
  end
  for i in C
    if S.resp[i] != resp_new && S.fs[i] > 0.0
      h = haskey(S.misc[i],"hc") ? S.misc[i]["hc"] : 1.0/sqrt(2.0)
      X = S.x[i]
      translate_resp!(X, S.fs[i], S.resp[i], resp_new, hc_old=h, hc_new=hc_new)

      # Changes: x, resp, misc["hc"]
      S.x[i] = X
      S.resp[i] = resp_new
      S.misc[i]["hc"] = hc_new
    end
  end
  return nothing
end
equalize_resp(S::SeisData, resp_new::Array{Complex{Float64},2};
  hc_new=1.0/sqrt(2.0)::Float64,
  C=Int64[]::Array{Int64,1} ) = (U = deepcopy(S); equalize_resp!(U, resp_new, hc_new=hc_new, C=C); return U)


# TO DO: accelerometer equation, unit-dependent conversion to pz format
"""
    resp = fctopz(fc)

Convert critical frequency fc to a matrix of complex poles and zeros. zeros are in resp[:,1], poles in resp[:,2].
"""
function fctopz(fc::T; hc=1.0/sqrt(2.0)::T, units="m/s"::String) where T
  pp = 2.0*pi
  if units == "m/s"
    cr = sqrt(complex(hc^2-1.0))
    cp = complex(zeros(T,2))
    cz = [-hc+cr, -hc-cr].*pp*fc
    return [cp cz]
  else
    error("NYI")
  end
end

"""
    Y = translate_resp!(X, fs, resp_old, resp_new)

Translate frequency response of `X`, sampled at `fs`, from `resp_old` to `resp_new`. zeros are in resp[:,1], poles in resp[:,2].
"""
function translate_resp!(X::Array{T,1}, fs::T,
  resp_old::Array{Complex{T},2}, resp_new::Array{Complex{T},2};
  hc_old=1.0/sqrt(2.0)::T, hc_new=1.0/sqrt(2.0)::T) where T

  resp_old == resp_new && return nothing
  pp = 2.0*Float64(pi)
  Nx = length(X)
  N2 = nextpow(2, Nx)
  f = [collect(0.0:1.0:N2/2.0); collect(-N2/2.0+1.0:1.0:-1.0)]*fs/N2  # Freqs
  F0 = resp_f(resp_old, hc_old, 1.0, f, fs)                           # Old resp
  F1 =  resp_f(resp_new, hc_new, 1.0, f, fs)                          # New resp
  xf = fft([X; zeros(T, N2-Nx)])                                      # FFT
  rf = F1.*conj(F0)./(F0.*conj(F0).+eps())
  X[:] = real(ifft(xf.*rf))[1:Nx]
  return nothing
end

resp_f(r::Array{Complex{T},2}, g::T, h::T, f::Array{T,1}, fs::T) where T = h*freqs(convert(PolynomialRatio, ZeroPoleGain([2.0; r[:,1]], [2.0; r[:,2]], g)), f, fs)
# resp_f(r::Array{Complex{T}, 2}, h::T, f::Array{T, 1}, fs::T) where T = h*freqs(convert(PolynomialRatio, ZeroPoleGain([2.0; r[:,1]], [2.0; r[:,2]], 1.0)), f, fs)
