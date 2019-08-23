export SeisPha

# ===========================================================================
# SeisPha
"""
    SeisPha()

IRIS-style seismic phase and pick container

Field     | Type    | Meaning         | SeisIO conventions/behavior
--------: |:------- |:--------------  | :----------
 amp      | Float64 | amplitude       | uses units of data source
 d        | Float64 | distance        | no unit conversion; can be m, km, or °
 ia       | Float64 | incidence angle | uses units of data source
 res      | Float64 | pick residual   |
 rp       | Float64 | ray parameter   |
 ta       | Float64 | takeoff angle   |
 tt       | Float64 | travel time     |
 unc      | Float64 | uncertainty     |
 pol      | Char    | polarity        |
 qual     | Char    | pick quality    | not (re)calculated

"""
mutable struct SeisPha
  amp ::Float64   # amplitude
  d   ::Float64   # distance
  ia  ::Float64   # incidence angle
  res ::Float64   # residual
  rp  ::Float64   # ray parameter
  ta  ::Float64   # takeoff angle
  tt  ::Float64   # travel time
  unc ::Float64   # uncertainty
  pol ::Char      # polarity
  qual::Char      # quality

  function SeisPha(
                    amp ::Float64 , # amplitude
                    d   ::Float64 , # distance
                    ia  ::Float64 , # incidence angle
                    res ::Float64 , # residual
                    rp  ::Float64 , # ray parameter
                    ta  ::Float64 , # takeoff angle
                    tt  ::Float64 , # travel time
                    unc ::Float64 , # uncertainty
                    pol ::Char    , # polarity
                    qual::Char      # quality
                    )
    return new(amp, d, ia, res, rp, ta, tt, unc, pol, qual)
  end
end

SeisPha( ;
        amp ::Float64   = zero(Float64),
        d   ::Float64   = zero(Float64),
        ia  ::Float64   = zero(Float64),
        res ::Float64   = zero(Float64),
        rp  ::Float64   = zero(Float64),
        ta  ::Float64   = zero(Float64),
        tt  ::Float64   = zero(Float64),
        unc ::Float64   = zero(Float64),
        pol ::Char      = ' ',
        qual::Char      = ' '
        ) = SeisPha(amp, d, ia, res, rp, ta, tt, unc, pol, qual)

function write(io::IO, Pha::SeisPha)
  write(io, Pha.amp)
  write(io, Pha.d)
  write(io, Pha.ia)
  write(io, Pha.res)
  write(io, Pha.rp)
  write(io, Pha.ta)
  write(io, Pha.tt)
  write(io, Pha.unc)
  write(io, Pha.pol)
  write(io, Pha.qual)
  return nothing
end

read(io::IO, ::Type{SeisPha}) =
  SeisPha(read(io, Float64),
          read(io, Float64),
          read(io, Float64),
          read(io, Float64),
          read(io, Float64),
          read(io, Float64),
          read(io, Float64),
          read(io, Float64),
          read(io, Char),
          read(io, Char)
          )

function isempty(Pha::SeisPha)
  q::Bool = min(getfield(Pha, :pol) == ' ', getfield(Pha, :qual) == ' ')
  if q == true
    for f in (:amp, :d, :ia, :res, :rp, :ta, :tt, :unc)
      q = min(q, getfield(Pha, f) == zero(Float64))
    end
  end
  return q
end

function isequal(S::SeisPha, U::SeisPha)
  q::Bool = isequal(getfield(S, :pol), getfield(U, :pol))
  if q == true
    for f in (:amp, :d, :ia, :res, :rp, :ta, :tt, :unc, :pol, :qual)
      q = min(q, getfield(S,f) == getfield(U,f))
    end
  end
  return q
end
==(S::SeisPha, U::SeisPha) = isequal(S, U)
sizeof(P::SeisPha) = 146
