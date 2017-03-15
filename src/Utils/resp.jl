# TO DO: accelerometer equation, unit-dependent conversion to pz format
"""
    resp = fctopz(fc)

Convert critical frequency fc to a matrix of complex poles and zeros. zeros are in resp[:,1], poles in resp[:,2].
"""
function fctopz{T}(fc::T; hc=1.0/sqrt(2)::T, units="m/s"::String)
  pp = 2.0*pi
  if units == "m/s"
    cr = sqrt(complex(hc^2-1))
    cp = complex(zeros(T,2))
    cz = [-hc+cr, -hc-cr].*pp*fc
    return [cp cz]
  else
    error("NYI")
  end
end

"""
    Y = translate_resp(X, fs, resp_old, resp_new)

Translate frequency response of `X`, sampled at `fs`, from `resp_old` to `resp_new`. zeros are in resp[:,1], poles in resp[:,2].
"""

function translate_resp!{T}(X::Array{T,1}, fs::T,
  resp_old::Array{Complex{T},2}, resp_new::Array{Complex{T},2};
  hc_old=1.0/sqrt(2.0)::T, hc_new=1.0/sqrt(2.0)::T)

  resp_old == resp_new && return nothing
  pp = 2.0*Float64(pi)
  Nx = length(X)
  N2 = nextpow2(Nx)
  f = [collect(0.0:1.0:N2/2.0); collect(-N2/2.0+1.0:1.0:-1.0)]*fs/N2  # Freqs
  F0 = SeisIO.resp_f(resp_old, hc_old, f, fs)                         # Old resp
  F1 = SeisIO.resp_f(resp_new, hc_new, f, fs)                         # New resp
  xf = fft([X; zeros(T, N2-Nx)])                                      # FFT
  rf = F1.*conj(F0)./(F0.*conj(F0).+eps())
  X[:] = real(ifft(xf.*rf))[1:Nx]
  return nothing
end

mkresp(r,g) = convert(PolynomialRatio, ZeroPoleGain([2.0,r[:,1]], [2.0,r[:,2]], g))

resp_f{T}(r::Array{Complex{T},2}, g::T, h::T, f::Array{T,1}, fs::T) = h*freqs(convert(PolynomialRatio, ZeroPoleGain([2.0; r[:,1]], [2.0; r[:,2]], g)), f, fs)
resp_f{T}(r::Array{Complex{T},2}, h::T, f::Array{T,1}, fs::T) = h*freqs(convert(PolynomialRatio, ZeroPoleGain([2.0; r[:,1]], [2.0; r[:,2]], 1.0)), f, fs)
