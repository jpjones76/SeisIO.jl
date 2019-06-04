function read_lenn_file!(S::SeisData, f::String)
  fname = realpath(f)
  id_sep = "."
  C = SeisChannel()
  nx = countlines(fname) - 1
  i = 1
  X = Array{Float32,1}(undef, nx)

  # file read
  io = open(fname, "r")
  h_line = readline(io)
  while !eof(io)
    v = mkfloat(io, 0x00)
    setindex!(X, v, i)
    i += 1
  end
  close(io)
  # file read

  h = split(h_line)
  sta = replace(h[3], "\'" => "")
  cmp = last(split(fname, id_sep))
  ts = (Date(h[8]).instant.periods.value)*86400000000 +
        div(Time(h[9]).instant.value, 1000) -
        dtconst
  T = Array{Int64,2}(undef, 2, 2)
  setindex!(T, one(Int64), 1)
  setindex!(T, Int64(nx), 2)
  setindex!(T, ts, 3)
  setindex!(T, zero(Int64), 4)

  setfield!(C, :fs, 1000.0 / parse(Float64, h[5]))
  setfield!(C, :id, *(id_sep, sta, id_sep, id_sep, cmp))
  setfield!(C, :name, *(sta, id_sep, cmp))
  setfield!(C, :src, fname)
  setfield!(C, :t, T)
  setfield!(C, :x, X)
  push!(S, C)
  return nothing
end
