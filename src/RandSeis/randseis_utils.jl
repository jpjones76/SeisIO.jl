ur2() = uppercase(randstring(2))

# Acceptable type codes in :misc
OK = [0x10, 0x11, 0x12, 0x13, 0x14, 0x20, 0x21, 0x22, 0x23, 0x24,
      0x30, 0x31, 0x32, 0x50, 0x51, 0x52, 0x53, 0x54, 0x60, 0x61, 0x62, 0x63,
      0x64, 0x70, 0x71, 0x72, 0x90, 0x91, 0x92, 0x93, 0x94, 0xa0,
      0xa1, 0xa2, 0xa3, 0xa4, 0xb0, 0xb1, 0xb2, 0xd0, 0xd1, 0xd2, 0xd3, 0xd4,
      0xe0, 0xe1, 0xe2, 0xe3, 0xe4, 0xf0, 0xf1, 0xf2]

# Fill :misc with garbage
function pop_rand_dict!(D::Dict{String,Any}, N::Int)
  for n = 1:N
    t = code2typ(rand(OK))
    k = randstring(rand(2:12))
    if Bool(t <: Real) == true
      D[k] = rand(t)
    elseif Bool(t <: Complex) == true
      D[k] = rand(Complex{real(t)})
    elseif Bool(t <: Array) == true
      y = eltype(t)
      if Bool(y <: Number) == true
        D[k] = rand(y, rand(1:1000))
      end
    end
  end
  if haskey(D, "hc")
    delete!(D, "hc")
  end
  return D
end

"""
   (i,c,u) = getyp2codes(b::Char, s=false::Bool)

Using band code `b`, generate quasi-sane random instrument char code (`i`)
and channel char code (`c`), plus unit string `u`. if s=true, use only seismic
data codes.
"""
function getyp2codes(b::Char, s=false::Bool)
  if s
    # Neglecting gravimeters ('G') and mass position sensors ('M')
    i = rand(['H','L','N'])
    if rand() > 0.2
      c = rand(['Z','N','E'])
    else
      c = rand(['A','B','C','1','2','3','U','V','W'])
    end
    if Base.in(i, ['H','L'])
      u = rand(["m", "m/s"])
    else
      u = "m/s^2"
    end
  else
    i = rand(['A','B','D','F','G','I','J','K','M','O','P','Q','R','S','T','U','V','W','Z'])
    if i == 'A' # tiltmeter
      c = rand(['N','E'])
      u = "rad"
    elseif i == 'B' # creep meter
      c = '_'
      u = "m"
      # C is calibration input
    elseif i == 'D' # pressure (barometer, infrasound, hydrophone ∈ 'D')
      c = rand(['O','I','D','F','H','U'])
      u = "Pa"
      # E is an electronic test point
    elseif i == 'F' # magnetometer
      c = rand(['Z','N','E'])
      u = "T"
    elseif i == 'G' # tiltmeter
        c = rand(['A','B','C','1','2','3','U','V','W'])
        u = "m/s^2"
    elseif i == 'I' # humidity
      c = rand(['O','I','D'])
      u = "%"
    elseif i == 'J' # rotational seismometer
      c = rand(['Z','N','E','A','B','C','T','R','1','2','3','U','V','W'])
      u = rand(["rad", "rad/s", "rad/s^2"])
    elseif i == 'K' # thermal (thermometer or radiometer)
      c = rand(['O', 'I', 'D'])
      u = rand(["C","K"])
    elseif i == 'M' # mass position sensor
        c = rand(['A','B','C','1','2','3','U','V','W'])
        u = "m"
    elseif i == 'O' # current gauge
      c = '_'
      u = "m/s"
    elseif i == 'P' # very short-period geophone
      c = rand(['Z','N','E'])
      u = rand(["m", "m/s", "m/s^2"])
    elseif i == 'Q' # voltmeter
      c = '_'
      u = "V"
    elseif i == 'R' # rain gauge
      c = '_'
      u = rand(["m", "m/s"])
    elseif i == 'S' # strain gauge
      c = rand(['Z','N','E'])
      u = "m/m"
    elseif i == 'T' # tide gauge
      c = 'Z'
      u = "m"
    elseif i == 'U' # bolometer
      c = '_'
      u = "(% cloud cover)"
    elseif i == 'V' # volumetric strainmeter
      c = '_'
      u = "m^3/m^3"
    elseif i == 'W' # wind speed ('S') or direction ('D')
      c = rand(['S','D'])
      u = c == 'S' ? "m/s" : "(direction vector)"

    # X, Y are instrument-specific...excluded

    elseif i == 'Z' # synthesized beam or stack
      c = rand(['I','C','F','O'])
      u = rand(["m", "m/s", "m/s^2"])
    end
  end
  return i,c,u
end
