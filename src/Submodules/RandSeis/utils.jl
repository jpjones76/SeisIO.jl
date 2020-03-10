rand_lat() = 180 * (rand()-0.5)
rand_lon() = 360 * (rand()-0.5)
rand_lon(m::Int64, n::Int64) = 360.0.*rand(Float64, m, n).-0.5
rand_datum() = rand() > 0.2 ? "WGS-84" : rand(geodetic_datum)

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
