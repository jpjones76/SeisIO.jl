import Base:show, size, summary

si(w::Int, i::Int) = show_os + w*(i-1)
showtail(io::IO, b::Bool) = b ? "…" : ""
float_str(x::Union{Float32,Float64}) = @sprintf("%.3e", x)
# maxgap(t::Array{Int64,2}) = @sprintf("%g", μs*maximum(t[2:end,2]))
ngaps(t::Array{Int64,2}) = max(0, size(t,1)-2)

function str_trunc(str::String, w::Integer)
  d = map(UInt8, collect(str))
  L = length(d)
  if L > w
    s3 = d[1:w-4]
    d = map(UInt8, collect(String([s3; codeunits("...")])))
  else
    d = d[1:min(w,L)]
  end
  return d
end

function str_head(s::String, W::Int)
  sd = ones(UInt8, W)*0x20
  sd[show_os-1-length(s):show_os-2] = map(UInt8, collect(uppercase(s)))
  sd[show_os-1:show_os] = codeunits(": ")
  return sd
end

function show_str(io::IO, S::Array{String,1}, w::Int, W::Int, s::String, b::Bool)
  sd = str_head(s, W)
  N = length(S)
  for i = 1:N
    st = si(w,i)
    d = str_trunc(S[i], w)
    sd[st+1:st+length(d)] = d
  end
  println(io, replace(String(sd),'\0' => ' '), showtail(io, b))
  return
end

function show_t(io::IO, T::Array{Array{Int64,2},1}, w::Int, W::Int, b::Bool)
  sd1 = str_head("T", W::Int)
  p = show_os
  for i = 1:length(T)
    if isempty(T[i])
      s = ""
    else
      s = timestamp(T[i][1,2]*μs)
    end
    sd1[p+1:p+length(s)] = codeunits(s)
    ng = map(UInt8, collect(string("(", ngaps(T[i]), " gaps)")))
    sd1[p+2+length(s):p+1+length(s)+length(ng)] = ng
    p += w
  end
  println(io, replace(String(sd1),'\0' => ' '), showtail(io, b))
  return
end

# Array{Union{Array{Float64,1},Array{Float32,1}},1}
# function show_x(io::IO, X::Array{Array{Float64,1},1}, w::Int, W::Int, tip::String, b::Bool)
function show_x(io::IO,
                X::Union{ Array{Array{Float64,1},1},
                          Array{Array{Float32,1},1},
                          Array{Union{Array{Float64,1}, Array{Float32,1}},1} },
                w::Int, W::Int, tip::String, b::Bool)
  N = length(X)
  str = zeros(UInt8, W, 6)
  str[show_os-length(tip)-1:show_os,1] = UInt8.(codeunits(tip * ": "))
  p = show_os
  i = 1
  while p < W && i <= N
    L = length(X[i])
    Lx = string("(nx = ", L, ")")
    if isempty(X[i])
      str[p+1:p+7,1] = codeunits("(empty)")
    else
      for k = 1:5
        if k <= L
          s = float_str(X[i][k])
          if (L > 5 && k==3)
            s = "  ..."
          elseif (L > 5 && k==4)
            s = float_str(last(X[i]))
          elseif (L > 5 && k==5)
            s = Lx
          end
        else
          s = ""
        end
        cstr = codeunits(s)
        str[p+1:p+length(cstr),k] = cstr
      end
    end
    p += w
    i += 1
  end
  for i = 1:5
    if i == 1
      println(io, replace(String(str[:,i]),'\0' => ' '), showtail(io, b))
    else
      println(io, replace(String(str[:,i]),'\0' => ' '))
    end
  end
  return
end

function resp_str(io::IO, X::Array{Array{Complex{Float64},2},1}, w::Int, W::Int, b::Bool)
  N = length(X); p = show_os; i = 1
  sd = zeros(UInt8, W, 2)
  sd[show_os-5:show_os-1,1] = codeunits("RESP:")
  while p < W && i <= N
    zstr = ""
    pstr = ""
    R = X[i]
    if isempty(R)
      zstr *= " "
      pstr *= " "
    else
      L = size(R,1)
      for j = 1:L
        zstr *= string(float_str(real(R[j,1])), " + ", float_str(imag(R[j,1])), "i")
        pstr *= string(float_str(real(R[j,2])), " + ", float_str(imag(R[j,2])), "i")
        if L > 1 && j < L
          zstr *= ", "
          pstr *= ", "
        end
        if length(zstr) > w
          zstr = zstr[1:w-4]*"..."
          pstr = pstr[1:w-4]*"..."
          break
        end
      end
    end
    q = length(zstr)
    sd[p+1:p+q,1] = codeunits(zstr)
    sd[p+1:p+q,2] = codeunits(pstr)
    p += w
    i += 1
  end
  [println(io, replace(String(sd[:,i]),'\0' => ' '), showtail(io,b)) for i=1:2]
  return
end

function show_conn(io::IO, C::Array{TCPSocket,1})
  d = str_head("C", show_os)
  println(io, replace(String(d),'\0' => ' '), sum([isopen(i) for i in C]), " open, ", length(C), " total")
  if !isempty(C)
    m = 1
    for c in C
      if isopen(c)
        (url,port) = getpeername(c)
        println(io, " "^show_os, "(", m, ") ", url, ":", Int(port))
      else
        println(io, " "^show_os, "(", m, ") (closed)")
      end
      m+=1
    end
  end
  return
end

summary(S::SeisHdr) = string(typeof(S), ", ", locsum(S.loc), ", mag = ", magsum(S.mag))
summary(S::SeisData) = string(typeof(S), " with ", S.n, " channel",  S.n == 1 ? "" : "s")
summary(S::SeisEvent) = string("Event ", S.hdr.id, ": ", typeof(S), " with ", S.data.n, " channel",
  S.data.n == 1 ? "" : "s")
summary(S::SeisChannel) = string(typeof(S), " with ", length(S.x), " sample",
  (length(S.x) == 1 ? "" : "s"), ", gaps: ", ngaps(S.t))

function show(io::IO, S::SeisData)
  W = max(80,displaysize(io)[2]-2)-show_os
  w = min(W, 36)
  nc = getfield(S, :n)
  N = min(nc, floor(Int, (W-show_os-3)/(w+1)))
  D = Array{String,1}(undef, 25)
  println(io, "SeisData with ", nc, " channels (", N, " shown)")
  show_str(io, S.id[1:N], w, W, "id", N<nc)
  show_str(io, S.name[1:N], w, W, "name", N<nc)
  show_x(io, S.loc[1:N], w, W, "LOC", N<nc)
  show_str(io, [@sprintf("%.04g", S.fs[i]) for i = 1:N], w, W, "fs", N<nc)
  show_str(io, [@sprintf("%.03e", S.gain[i]) for i = 1:N], w, W, "gain", N<nc)
  resp_str(io, S.resp[1:N], w, W, N<nc)
  show_str(io, S.units[1:N], w, W, "units",N<nc)
  show_str(io, S.src[1:N], w, W, "src", N<nc)
  show_str(io, [string(length(S.notes[i]), " entries") for i = 1:N],w,W,"NOTES",N<nc)
  show_str(io, [string(length(S.misc[i]), " items") for i = 1:N],w,W,"MISC",N<nc)
  show_t(io, S.t[1:N], w, W, N<nc)
  show_x(io, S.x[1:N], w, W, "DATA", N<nc)
  show_conn(io, S.c)
  return nothing
end
show(S::SeisData) = show(stdout, S)

function show(io::IO, S::SeisChannel)
  loc_str = ["lat", "lon", "ele", "az", "inc"]
  W = max(80,displaysize(io)[2]-2)-show_os
  w = min(W, 36)
  D = Array{String,1}(undef,25)
  nx = length(S.x)
  println(io, "SeisChannel with ", nx, " samples")
  show_str(io, [S.id], w, W, "id", false)
  show_str(io, [S.name], w, W, "name", false)
  show_x(io, [S.loc], w, W, "LOC", false)
  # [show_str(io, [string(S.loc[j])], w, W, loc_str[j], false) for j=1:5]
  # show_x(io, [S.loc], w, W, N<nc)
  show_str(io, [string(S.fs)], w, W, "fs", false)
  show_str(io, [float_str(S.gain)], w, W, "gain", false)
  resp_str(io, [S.resp], w, W, false)
  show_str(io, [S.units], w, W, "units",false)
  show_str(io, [S.src], w, W, "src", false)
  show_str(io, [string(length(S.notes), " entries")], w, W, "NOTES", false)
  show_str(io, [string(length(S.misc), " items")], w, W, "MISC", false)
  show_t(io, [S.t], w, W, false)
  show_x(io, [S.x], w, W, "DATA", false)
  return nothing
end
show(S::SeisChannel) = show(stdout, S)

magsum(mag::Tuple{Float32, String}) = string(mag[2], " ", mag[1])
locsum(loc::Array{Float64,1}) = @sprintf("%.5f°N, %.5f°E, %.3f km", loc[1], loc[2], loc[3])

function show(io::IO, S::SeisHdr)
  W = max(80,displaysize(io)[2]-2)-show_os
  println(io, "    ID: ", S.id)
  println(io, "    OT: ", S.ot)
  println(io, "   LOC: ", locsum(S.loc))
  println(io, "   MAG: ", magsum(S.mag), " (", S.int[2], " ", S.int[1], ")")
  println(io, "    MT: ", S.mt[1:6], " (M\u2080=", S.mt[7], ", %DC=", S.mt[8], ")")
  println(io, "    NP: ", S.np[1], ", ", S.np[2])
  println(io, "  AXES: ", S.pax[1],", ", S.pax[2], ", ", S.pax[3])
  println(io, "   SRC: ", String(str_trunc(S.src, W)))
  println(io, " NOTES: ", length(S.notes), " entries")
  println(io, "  MISC: ", length(S.misc), " items")
  return nothing
end
show(S::SeisHdr) = show(stdout, S)

function show(io::IO, S::SeisEvent)
  println(io, summary(S))
  println(io, "\n(.hdr)")
  show(io, S.hdr)
  println(io, "\n(.data)")
  println(io, "SeisIO.SeisData with ", S.data.n, " channels")
  return nothing
end
show(S::SeisEvent) = show(stdout, S)
