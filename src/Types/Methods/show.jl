import Base:show, size, summary

si(w::Int, i::Int) = show_os + w*(i-1)
showtail(io::IO, b::Bool) = b ? "…" : ""
float_str(x::Union{Float32,Float64}) = @sprintf("%.3e", x)
# maxgap(t::Array{Int64,2}) = @sprintf("%g", μs*maximum(t[2:end,2]))
ngaps(t::Array{Int64,2}) = max(0, size(t,1)-2)

function str_trunc(str::String, w::Integer)
  d = UInt8.(codeunits(str))
  L = length(d)
  if L > w
    s = d[1:w-4]
    d = vcat(s, UInt8[0x2e, 0x2e, 0x2e])
  else
    d = d[1:min(w,L)]
  end
  return d
end

function str_head(s::String, W::Int)
  sd = ones(UInt8, W)*0x20
  sd[show_os-1-length(s):show_os-2] = codeunits(uppercase(s))
  sd[show_os-1:show_os] = codeunits(": ")
  return sd
end

function show_str(io::IO, S::Array{String,1}, w::Int, W::Int, s::String, b::Bool)
  sd = str_head(s, W)
  N = length(S)
  for i = 1:N
    st = si(w,i)
    d = str_trunc(S[i], w)
    sd[st+1:st+length(d)] .= d
  end
  println(io, String(sd), showtail(io, b))
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
    ng = codeunits(string("(", ngaps(T[i]), " gaps)"))
    sd1[p+1+length(s):p+length(s)+length(ng)] = ng
    p += w
  end
  println(io, replace(String(sd1),'\0' => ' '), showtail(io, b))
  return
end

# Array{FloatArray,1}
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

summary(S::SeisHdr) = string(typeof(S), ", ", repr("text/plain", S.loc, context=:compact=>true), ", mag = ", magsum(S.mag))
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
  show_str(io, String[repr("text/plain", S.loc[i], context=:compact=>true) for i=1:N], w, W, "LOC", N<nc)
  show_str(io, String[repr("text/plain", S.fs[i], context=:compact=>true) for i=1:N], w, W, "fs", N<nc)
  show_str(io, [@sprintf("%.03e", S.gain[i]) for i = 1:N], w, W, "gain", N<nc)
  show_str(io, String[repr("text/plain", S.resp[i], context=:compact=>true) for i=1:N], w, W, "RESP", N<nc)
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

function show(io::IO, C::SeisChannel)
  loc_str = ["lat", "lon", "ele", "az", "inc"]
  W = max(80,displaysize(io)[2]-2)-show_os
  w = min(W, 36)
  D = Array{String,1}(undef,25)
  nx = length(C.x)
  println(io, "SeisChannel with ", nx, " samples")
  show_str(io, [C.id], w, W, "id", false)
  show_str(io, [C.name], w, W, "name", false)
  show_str(io, [repr("text/plain", C.loc, context=:compact=>true)], w, W, "LOC", false)
  show_str(io, [string(C.fs)], w, W, "fs", false)
  show_str(io, [float_str(C.gain)], w, W, "gain", false)
  show_str(io, [repr("text/plain", C.resp, context=:compact=>true)], w, W, "RESP", false)
  show_str(io, [C.units], w, W, "units",false)
  show_str(io, [C.src], w, W, "src", false)
  show_str(io, [string(length(C.notes), " entries")], w, W, "NOTES", false)
  show_str(io, [string(length(C.misc), " items")], w, W, "MISC", false)
  show_t(io, [C.t], w, W, false)
  show_x(io, [C.x], w, W, "DATA", false)
  return nothing
end
show(C::SeisChannel) = show(stdout, C)

magsum(mag::Tuple{Float32, String}) = string(mag[2], " ", mag[1])

function show(io::IO, H::SeisHdr)
  W = max(80,displaysize(io)[2]-2)-show_os
  println(io, "    ID: ", H.id)
  println(io, "    OT: ", H.ot)
  println(io, "   LOC: ", repr("text/plain", H.loc, context=:compact=>true))
  println(io, "   MAG: ", magsum(H.mag), " (", H.int[2], " ", H.int[1], ")")
  println(io, "    MT: ", repr("text/plain", H.mt, context=:compact=>true))
  println(io, "  AXES: ", repr("text/plain", H.axes, context=:compact=>true))
  println(io, "   SRC: ", String(str_trunc(H.src, W)))
  println(io, " NOTES: ", length(H.notes), " entries")
  println(io, "  MISC: ", length(H.misc), " items")
  return nothing
end
show(S::SeisHdr) = show(stdout, S)

function show(io::IO, TD::EventTraceData)
  W = max(80,displaysize(io)[2]-2)-show_os
  w = min(W, 36)
  nc = getfield(TD, :n)
  N = min(nc, floor(Int, (W-show_os-3)/(w+1)))
  D = Array{String,1}(undef, 25)
  println(io, typeof(TD), " with ", nc, " channels (", N, " shown)")

  # Strings
  for f in (:id, :name, :units, :src)
    show_str(io, getfield(TD, f)[1:N], w, W, String(f), N<nc)
  end

  # Floats, Loc, Reps
  for f in (:fs, :gain, :loc, :resp, :az, :baz, :dist)
    show_str(io, String[repr("text/plain", getindex(getfield(TD, f), i), context=:compact=>true) for i=1:N], w, W,  String(f), N<nc)
  end

  # Phases
  show_str(io, [string(length(TD.pha[i]), " phases") for i = 1:N],w,W,"PHA",N<nc)

  # Notes
  show_str(io, [string(length(TD.notes[i]), " entries") for i = 1:N],w,W,"NOTES",N<nc)

  # Misc
  show_str(io, [string(length(TD.misc[i]), " items") for i = 1:N],w,W,"MISC",N<nc)

  # Channel times
  show_t(io, TD.t[1:N], w, W, N<nc)

  # Channel data
  show_x(io, TD.x[1:N], w, W, "DATA", N<nc)
  return nothing
end
show(TD::EventTraceData) = show(stdout, TD)

function show(io::IO, S::SeisEvent)
  println(io, summary(S))
  println(io, "\n(.hdr)")
  show(io, S.hdr)
  println(io, "\n(.data)")
  println(io, "EventTraceData with ", S.data.n, " channels")
  return nothing
end
show(S::SeisEvent) = show(stdout, S)
