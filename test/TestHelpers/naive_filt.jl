function naive_filt!(C::SeisChannel;
  fl::Float64=1.0,
  fh::Float64=15.0,
  np::Int=4,
  rp::Int=10,
  rs::Int=30,
  rt::String="Bandpass",
  dm::String="Butterworth"
  )

  T = eltype(C.x)
  fe = 0.5 * C.fs
  low = T(fl / fe)
  high = T(fh / fe)

  # response type
  if rt == "Highpass"
    ff = Highpass(fh, fs=fs)
  elseif rt == "Lowpass"
    ff = Lowpass(fl, fs=fs)
  else
    ff = getfield(DSP.Filters, Symbol(rt))(fl, fh, fs=fs)
  end

  # design method
  if dm == "Elliptic"
    zp = Elliptic(np, rp, rs)
  elseif dm == "Chebyshev1"
    zp = Chebyshev1(np, rp)
  elseif dm == "Chebyshev2"
    zp = Chebyshev2(np, rs)
  else
    zp = Butterworth(np)
  end

  # polynomial ratio
  pr = convert(PolynomialRatio, digitalfilter(ff, zp))

  # zero-phase filter
  C.x[:] = filtfilt(pr, C.x)
  return nothing
end
