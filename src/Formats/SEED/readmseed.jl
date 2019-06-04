# export readmseed, readmseed!

function seed_cleanup!(S::SeisData, BUF::SeisIOBuf)
  trunc_x!(S)
  fill!(getfield(BUF, :hdr_old), zero(UInt8))
  setfield!(BUF, :r1_old, zero(Int16))
  setfield!(BUF, :r2_old, zero(Int16))
  return nothing
end

function parsemseed!(S::SeisData, sid::IO, v::Int64, nx_new::Int64, nx_add::Int64)
  while !eof(sid)
    parserec!(S, BUF, sid, v, nx_new, nx_add)
  end
  seed_cleanup!(S, BUF)
  return S
end

function read_seed_file!(S::SeisData, fname::String, v::Int64, nx_new::Int64, nx_add::Int64)
  io = open(fname, "r")
  skip(io, 6)
  c = read(io, UInt8)
  if c in (0x44, 0x52, 0x4d, 0x51)
    seekstart(io)
    parsemseed!(S, io, v, nx_new, nx_add)
    close(io)
  else
    error("Invalid file type!")
  end
  return nothing
end
