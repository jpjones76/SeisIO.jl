using DSP

# TO DO: accelerometer equation, unit-dependent conversion to pz format
"""
    resp = fctopz(fc)

Convert critical frequency fc to a matrix of complex poles and zeros. zeros are
in resp[:,1], poles in resp[:,2].
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

function translate_resp{T}(X::Array{T,1}, fs::T, resp_old::Array{Complex{T},2}, resp_new::Array{Complex{T},2}; gain=1.0::T)
  pp = 2.0*pi
  if resp_old==resp_new
    warn("resp_old==resp_new; gain normalized, nothing else to do.")
    return X./gain
  end
  Nx = length(X)
  N2 = nextpow2(Nx)
  f = [collect(0:N2/2); collect(-N2/2+1:-1)]*fs/N2

  # Old instrument response
  F0 = hc_old*freqs(mkresp(resp_old, gain), f, fs)

  # New instrument response
  F1 = hc_new*freqs(mkresp(resp_new, 1.0), f, fs)

  # FFT
  xf = fft([X; zeros(T, N2-Nx)])
  rf = F1.*conj(F0)./(F0.*conj(F0).+eps())
  Xo = real(ifft(xf.*rf))
  return Xo[1:Nx]
end

function equalize_resp!{T}(S::SeisData, resp_new::Array{Complex{T},2})
  pp = 2.0*pi
  for i = 1:1:S.n
    if haskey(S.misc[i],"normfac")
      h = S.misc[i]["normfac"]
    else
      h = 1.0
    end
    X = S.x[i]
    Nx = length(X)
    N2 = nextpow2(Nx)
    fs = S.fs[i]
    f = [collect(0:N2/2); collect(-N2/2+1:-1)]*fs/N2

    # Old instrument response
    F0 = resp_f(S.resp[i], S.gain[i], h, f, fs) #hc_old*freqs(mkresp(S.resp[i], S.gain[i]), f, fs)

    # New instrument response
    F1 = resp_f(resp_new, 1.0, 1.0/sqrt(2), f, fs)

    # FFT
    xf = fft([X; zeros(T, N2-Nx)])
    rf = F1.*conj(F0)./(F0.*conj(F0).+eps())

    # Changes: x, resp, gain, misc["normfac"]
    S.x[i] = real(ifft(xf.*rf))[1:Nx]
    S.resp[i] = resp_new
    S.gain[i] = 1.0
    S.misc[i]["normfac"] = 1.0
  end
  return S
end

mkresp(r,g) = convert(PolynomialRatio, ZeroPoleGain([2.0,r[:,1]], [2.0,r[:,2]], g))

resp_f(r, g, h, f, fs) = h*freqs(convert(PolynomialRatio, ZeroPoleGain([2.0; r[:,1]], [2.0; r[:,2]], g)), f, fs)
