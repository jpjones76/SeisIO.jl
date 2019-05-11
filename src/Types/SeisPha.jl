export PhaseCat, SeisPha

# ===========================================================================
# SeisPha
mutable struct SeisPha
  d ::Float64 # distance
  tt::Float64 # travel time
  rp::Float64 # ray parameter
  ta::Float64 # takeoff angle
  ia::Float64 # incidence angle
  pol::Char   # polarity

  function SeisPha(
                    d ::Float64,
                    tt::Float64,
                    rp::Float64,
                    ta::Float64,
                    ia::Float64,
                    pol::Char
                    )
    return new(d, tt, rp, ta, ia, pol)
  end
end

SeisPha( ;
        d ::Float64   = zero(Float64),
        tt::Float64   = zero(Float64),
        rp::Float64   = zero(Float64),
        ta::Float64   = zero(Float64),
        ia::Float64   = zero(Float64),
        pol::Char     = ' '
        ) = SeisPha(d, tt, rp, ta, ia, pol)

function write(io::IO, Pha::SeisPha)
  for f in (:d, :tt, :rp, :ta, :ia, :pol)
    write(io, getfield(Pha, f))
  end
  return nothing
end

read(io::IO, ::Type{SeisPha}) =
  SeisPha(read(io, Float64),
          read(io, Float64),
          read(io, Float64),
          read(io, Float64),
          read(io, Float64),
          read(io, Char))

function isempty(Pha::SeisPha)
  q::Bool = getfield(Pha, :pol) == ' '
  if q == false
    return q
  else
    for f in (:d, :tt, :rp, :ta, :ia)
      q = min(q, getfield(Pha, f) == zero(Float64))
    end
    return q
  end
end

function isequal(S::SeisPha, U::SeisPha)
  q::Bool = isequal(getfield(S, :pol), getfield(U, :pol))
  if q == true
    for f in (:d, :tt, :rp, :ta, :ia)
      q = min(q, getfield(S,f) == getfield(U,f))
    end
  end
  return q
end
==(S::SeisPha, U::SeisPha) = isequal(S, U)
sizeof(P::SeisPha) = 102

# ===========================================================================
# PhaseCat
const PhaseCat = Dict{String, SeisPha}

function show(io::IO, PC::PhaseCat)
  if get(io, :compact, false) == false
    phase_names = sort(collect(keys(PC)))
    npha = length(phase_names)
    sep = " |"
    w = 8
    ww = 16
    c = :compact => true
    F = (:d, :tt, :rp, :ta, :ia, :pol)
    print(io, lpad("Phase Name", ww))
    print(io, sep, lpad("Dist", w))
    print(io, sep, lpad("Travel", w))
    print(io, sep, lpad("Ray", w))
    print(io, sep, lpad("Takeoff", w))
    print(io, sep, lpad("Inc", w))
    print(io, sep, " Pol\n")
    print(io, lpad(string("(", npha, " phases)"), ww))
    print(io, sep, " "^w)
    print(io, sep, lpad("Time", w))
    print(io, sep, lpad("Param", w))
    print(io, sep, lpad("Angle", w))
    print(io, sep, lpad("Angle", w))
    print(io, sep, " "^9, "\n ", "="^(ww), "+")
    for j = 1:5
      print(io, "="^(w+1), "+")
    end
    print(io, "="^4, "\n")

    for i = 1:npha
      pha = phase_names[i]
      print(io, lpad(string("\"", pha, "\""), ww))
      print(io, sep)
      Pha = get(PC, pha, SeisPha())
      j = 0
      for f in F
        j += 1
        if j < 6
          print(io, lpad(repr(getfield(Pha, f), context=c), w))
          print(io, sep)
        else
          print(io, " ", repr(getfield(Pha, f), context=c), "\n")
        end
      end
    end
  end
end

function write(io::IO, PC::PhaseCat)
  K = collect(keys(PC))
  L = Int64(length(K))
  write(io, L)
  if !isempty(PC)
    ksep = get_separator(join(K))
    karr = UInt8.(codeunits(join(K, ksep)))
    l = Int64(length(karr))
    write(io, l)
    write(io, ksep)
    write(io, karr)
    for (n,i) in enumerate(K)
      write(io, PC[i])
    end
  end
  return nothing
end

function read(io::IOStream, ::Type{PhaseCat})
  PC = PhaseCat()
  L = read(io, Int64)
  if L > 0
    l = read(io, Int64)
    ksep = Char(read(io, UInt8))
    kstr = String(read(io, l))
    K = collect(split(kstr, ksep))
    for k in K
      PC[k] = read(io, SeisPha)
    end
  end
  return PC
end
