export PhaseCat, show_phases

# PhaseCat
"Type alias of Dict{String, SeisPha}; see ?SeisPha() for field definitions."
const PhaseCat = Dict{String, SeisPha}

function write(io::IO, PC::PhaseCat)
  L = Int64(length(PC))
  write(io, L)
  if L != zero(Int64)
    K = keys(PC)
    write_string_vec(io, collect(K))
    for V in values(PC)
      write(io, V)
    end
  end
  return nothing
end

function read(io::IO, ::Type{PhaseCat})
  PC = PhaseCat()
  L = read(io, Int64)
  if L != zero(Int64)
    u = getfield(BUF, :buf)
    checkbuf!(u, 65535)
    K = read_string_vec(io, u)
    for k in K
      PC[k] = read(io, SeisPha)
    end
  end
  return PC
end

function show_phases(io::IO, PC::PhaseCat)
  phase_names = sort(collect(keys(PC)))
  npha = length(phase_names)
  w = 10
  ww = 16
  c = :compact => true
  F = (:amp, :d, :ia, :res, :rp, :ta, :tt, :unc, :pol, :qual)
  print(io, lpad("Phase", ww))
  print(io, lpad("Amplitude", w))
  print(io, lpad("Distance", w))
  print(io, lpad("Incidence", w))
  print(io, lpad("Residual", w))
  print(io, lpad("Ray Param", w))
  print(io, lpad("Takeoff", w))
  print(io, lpad("Time", w))
  print(io, lpad("Unc", w))
  print(io, "  P  Q\n")
  print(io, "="^ww, "+")
  for j = 1:8
    print(io, "="^(w-1), "+")
  end
  print(io, "==+==", "\n")

  for i = 1:npha
    pha = phase_names[i]
    print(io, rpad(string("\"", pha, "\""), ww))
    Pha = get(PC, pha, SeisPha())
    j = 0
    for f in F
      j += 1
      if j < 9
        @printf(io, "%10.3g", getfield(Pha, f))
      elseif j == 9
        print(io, "  ", string(getfield(Pha, f)))
      else
        print(io, "  ", string(getfield(Pha, f), "\n"))
      end
    end
  end
end
show_phases(PC::PhaseCat) = show_phases(stdout, PC)
