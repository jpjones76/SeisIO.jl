rand_lat() = 180 * (rand()-0.5)
rand_lon() = 360 * (rand()-0.5)
rand_lon(m::Int64, n::Int64) = 360.0.*rand(Float64, m, n).-0.5

function rand_datum()
  x = rand()
  return x > 0.2 ? "WGS-84 " : x > 0.1 ? "ETRS89 " : x > 0.05 ? "GRS 80 " : "JGD2011"
end

# Fill :misc with garbage
function rand_misc(N::Integer)
  D = Dict{String, Any}()
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
  (haskey(D, "hc")) && (delete!(D, "hc"))
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
    if i == 'N'
      u = "m/s2"
    else
      u = rand(["m", "m/s"])
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
        u = "m/s2"
    elseif i == 'I' # humidity
      c = rand(['O','I','D'])
      u = "%"
    elseif i == 'J' # rotational seismometer
      c = rand(['Z','N','E','A','B','C','T','R','1','2','3','U','V','W'])
      u = rand(["rad", "rad/s", "rad/s2"])
    elseif i == 'K' # thermal (thermometer or radiometer)
      c = rand(['O', 'I', 'D'])
      u = rand(["Cel","K"])
    elseif i == 'M' # mass position sensor
        c = rand(['A','B','C','1','2','3','U','V','W'])
        u = "m"
    elseif i == 'O' # current gauge
      c = '_'
      u = "m/s"
    elseif i == 'P' # very short-period geophone
      c = rand(['Z','N','E'])
      u = rand(["m", "m/s", "m/s2"])
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
      u = "%{cloud_cover}"
    elseif i == 'V' # volumetric strainmeter
      c = '_'
      u = "m3/m3"
    elseif i == 'W' # wind speed ('S') or direction ('D')
      c = rand(['S','D'])
      u = c == 'S' ? "m/s" : "{direction_vector}"

    # X, Y are instrument-specific...excluded
    elseif i == 'Z' # synthesized beam or stack
      c = rand(['I','C','F','O'])
      u = rand(["m", "m/s", "m/s2"])
    end
  end
  return i,c,u
end

function repop_id!(S::GphysData; s::Bool=true)
  while length(unique(S.id)) < length(S.id)
    for i = 1:S.n
      fs = S.fs[i]
      if fs == 0.0
        S.id[i] = rand_irr_id()
      else
        S.id[i], S.units[i] = rand_reg_id(fs, s)
      end
    end
  end
  return nothing
end
