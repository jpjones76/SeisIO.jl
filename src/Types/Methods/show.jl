showtail(b::Bool) = b ? "…" : ""
ngaps(t::Array{Int64,2}) = max(0, size(t,1)-2)

function str_trunc(s::String, w::Int64)
  L = length(s)
  if L ≥ w
    return s[1:w-2] * "… "
  else
    return rpad(s, w)
  end
end

function show_str(io::IO, S::Array{String,1}, w::Int, N::Int64)
  for i = 1:N
    print(io, str_trunc(S[i], w))
  end
  println(io, showtail(N<length(S)))
  return nothing
end
# 
# function show_float(io::IO, X::FloatArray, w::Int, N::Int64)
#   for i = 1:N
#      print(io, rpad(@sprintf("%+10.3e", X[i]), w))
#   end
#   println(io, showtail(N<length(S)))
#   return nothing
# end

function show_t(io::IO, T::Array{Array{Int64,2},1}, w::Int, N::Int64)
  for i = 1:N
    if isempty(T[i])
      s = ""
    else
      s = string(timestamp(T[i][1,2]*μs), " (", ngaps(T[i]), " gaps)")
    end
    print(io, str_trunc(s, w))
  end
  println(io, showtail(N<length(T)))
  return
end

function mkxstr(N, X::Union{Array{Array{Float64,1},1},
                            Array{Array{Float32,1},1},
                            Array{Union{Array{Float64,1}, Array{Float32,1}},1}})

  # Fill matrix of X values
  vx = 5
  X_str = Array{String,2}(undef, vx, N)
  fill!(X_str, "")
  for j = 1:N
    x = getindex(X, j)
    nx = lastindex(x)
    if nx == 0
      X_str[1,j] = "(empty)"
      continue
    elseif nx < vx
      for i = 1:nx
        X_str[i,j] = @sprintf("%+10.3e", x[i])
      end
    else
      nx_str          = string(nx)
      for i = 1:vx-3
        X_str[i,j]    = @sprintf("%+10.3e", x[i])
      end
      X_str[vx-2,j]   = "    ..."
      X_str[vx-1,j]   = @sprintf("%+10.3e", x[nx])
      X_str[vx,j]     = string("(nx = ", nx_str, ")")
    end
  end
  return X_str
end

# Fill matrix of X value strings
function mkxstr(X::FloatArray)
  vx = 5
  X_str = Array{String,2}(undef, vx, 1)
  fill!(X_str, "")
  nx = lastindex(X)
  if nx == 0
    X_str[1,1]      = "(empty)"
  elseif nx < vx
    for i = 1:nx
      X_str[i,1]    = @sprintf("%+10.3e", X[i])
    end
  else
    nx_str          = string(nx)
    for i = 1:vx-3
      X_str[i,1]    = @sprintf("%+10.3e", X[i])
    end
    X_str[vx-2,1]   = "    ..."
    X_str[vx-1,1]   = @sprintf("%+10.3e", X[nx])
    X_str[vx,1]     = string("(nx = ", nx_str, ")")
  end
  return X_str
end

function show_x(io::IO, X_str::Array{String,2}, w::Int64, b::Bool)
  (vx, N) = size(X_str)

  # Display
  for i = 1:vx
    if i > 1
      print(io, " "^show_os)
    end

    for j = 1:N
      x_str = X_str[i,j]
      L = length(x_str)
      print(io, x_str)
      if (x_str == "(empty)" || x_str == "") && N == 1
        return nothing
      end
      print(io, " "^(w-L))
    end
    print(io, showtail(b))
    if i < vx
      print(io, "\n")
    end
  end
  return nothing
end

function show_conn(io::IO, C::Array{TCPSocket,1})
  print(io, string(sum([isopen(i) for i in C]), " open, ", length(C), " total"))
  if !isempty(C)
    for (m,c) in enumerate(C)
      print(io, "\n")
      if isopen(c)
        (url,port) = getpeername(c)
        print(io, " "^show_os, "(", m, ") ", url, ":", Int(port))
      else
        print(io, " "^show_os, "(", m, ") (closed)")
      end
    end
  end
  return nothing
end

summary(S::GphysData) = string(typeof(S), " with ", S.n, " channel",  S.n == 1 ? "" : "s")
summary(S::GphysChannel) = string(typeof(S), " with ",
  length(S.x), " sample", (length(S.x) == 1 ? "" : "s"), ", gaps: ", ngaps(S.t))
# summary(H::SeisHdr) = string(typeof(H), ", ",
#   repr("text/plain", H.loc, context=:compact=>true), ", ",
#   repr("text/plain", H.mag, context=:compact=>true), ", ",
#   repr("text/plain", H.mag, context=:compact=>true), ", ",
#   H.int[2], " ", H.int[1])
# summary(V::SeisEvent) = string("Event ", V.hdr.id, ": ", typeof(V), " with ",
#   V.data.n, " channel", V.data.n == 1 ? "" : "s")

# GphysData
function show(io::IO, S::T) where {T<:GphysData}
  W = max(80, displaysize(io)[2]) - show_os
  w = min(W, 35)
  nc = getfield(S, :n)
  N = min(nc, div(W-1, w))
  M = min(N+1, nc)
  println(io, T, " with ", nc, " channels (", N, " shown)")
  F = fieldnames(T)
  for f in F
    if (f in unindexed_fields) == false
      targ = getfield(S, f)
      t = typeof(targ)
      fstr = uppercase(String(f))
      print(io, lpad(fstr, show_os-2), ": ")
      if t == Array{String,1}
        show_str(io, targ, w, N)
      elseif f == :notes || f == :misc
        show_str(io, String[string(length(getindex(targ, i)), " entries") for i = 1:M], w, N)
      elseif f == :pha
        show_str(io, String[string(length(getindex(targ, i)), " phases") for i = 1:M], w, N)
      elseif f == :t
        show_t(io, targ, w, N)
      elseif f == :x
        x_str = mkxstr(N, getfield(S, :x))
        show_x(io, x_str, w, N<nc)
      else
        show_str(io, String[repr("text/plain", targ[i], context=:compact=>true) for i = 1:M], w, N)
      end
    elseif f == :c
      print(io, "\n", lpad("C", show_os-2), ": ")
      show_conn(io, S.c)
    end
  end
  return nothing
end
show(S::SeisData) = show(stdout, S)

# GphysChannel
function show(io::IO, C::T) where T<:GphysChannel
  W = max(80,displaysize(io)[2]-2)-show_os
  w = min(W, 36)
  nx = length(C.x)
  F = fieldnames(T)

  println(io, T, " with ", nx, " samples")
  for f in F
    targ = getfield(C, f)
    t = typeof(targ)
    fstr = uppercase(String(f))
    print(io, lpad(fstr, show_os-2), ": ")
    if t == String
      println(io, targ)
    elseif (t <: AbstractFloat || t <: InstrumentPosition || t<: InstrumentResponse)
      println(io, repr("text/plain", targ, context=:compact=>true))
    elseif f == :notes
      println(io, string(length(targ), " entries"))
    elseif f == :misc
      println(io, string(length(targ), " entries"))
    elseif f == :pha
      println(io, string(length(targ), " phases"))
    elseif f == :t
      show_t(io, [targ], w, 1)
    else
      x_str = mkxstr(getfield(C, :x))
      show_x(io, x_str, w, false)
    end
  end
  return nothing
end
show(C::GphysChannel) = show(stdout, C)
