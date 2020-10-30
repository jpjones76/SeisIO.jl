function seed_cleanup!(S::SeisData, BUF::SeisIOBuf)
  trunc_x!(S)
  fill!(getfield(BUF, :hdr_old), zero(UInt8))
  setfield!(BUF, :r1_old, zero(Int16))
  setfield!(BUF, :r2_old, zero(Int16))
  return nothing
end

function parsemseed!(S::SeisData, io::IO, nx_new::Int64, nx_add::Int64, strict::Bool, v::Integer)
  while !eof(io)
    parserec!(S, BUF, io, nx_new, nx_add, strict, v)
  end
  seed_cleanup!(S, BUF)
  return nothing
end

function read_mseed_file!(S::SeisData, fname::String,  nx_new::Int64, nx_add::Int64, memmap::Bool, strict::Bool, v::Integer)
  io  = memmap ? IOBuffer(Mmap.mmap(fname)) : open(fname, "r")
  fastskip(io, 6)
  c = fastread(io)
  if c in (0x44, 0x52, 0x4d, 0x51)
    seekstart(io)
    parsemseed!(S, io, nx_new, nx_add, strict, v)
    close(io)
  else
    close(io)
    error("Invalid file type!")
  end
  return nothing
end
