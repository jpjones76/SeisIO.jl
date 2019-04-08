export readmseed, readmseed!

function parsemseed!(S::SeisData, sid::IO, v::Int)
  while !eof(sid)
    parserec!(S, sid, v)
  end
  trunc_x!(S)
  return S
end

"""
    S = readmseed(fname)

Read file S into a SeisData structure.

  readmseed!(S, fname)

Read `fname` into `S`.

Note: this is a mini-SEED reader,. not a full SEED reader. Currently supported
SEED blockette types include [100], [201], [500], [1000], [1001].

Keywords:
* swap: Byte swap. Set false for no (little-Endian). readmseed should be able
to determinme whether to byte swap automatically; only use this keyword if you
encounter errors. (Default: false)
* v: Verbosity. (Default: 0)
"""
function readmseed!(S::SeisData, fname::String; swap=false::Bool, v::Int=KW.v)
  setfield!(SEED, :swap, swap)

  if safe_isfile(fname)
    fid = open(fname, "r")
    skip(fid, 6)
    (findfirst(isequal(read(fid, Char)), "DRMQ") > 0) || error("Scan failed due to invalid file type")
    seek(fid, 0)
    parsemseed!(S, fid, v)
    close(fid)
  else
    error("Invalid file name!")
  end
  return nothing
end
readmseed(fname::String; swap=false::Bool, v::Int=KW.v) = (S = SeisData(); readmseed!(S, fname, swap=swap, v=v); return S)
