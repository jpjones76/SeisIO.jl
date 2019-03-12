export readmseed, readmseed!

function parsemseed!(S::SeisData, sid::IO, v::Int)
  while !eof(sid)
    parserec!(S, sid, v)
  end
  for i = 1:S.n
    L = size(S.t[i], 1)
    if L == 0
      S.x[i] = Array{Float64,1}(undef, 0)
      S.fs[i] = 0.0
    else
      nx = S.t[i][L,1]
      if length(S.x[i]) > nx
        resize!(S.x[i], nx)
      end
    end
  end
  return S
end

"""
    S = readmseed(fname)

Read file fname in big-Endian mini-SEED format. Returns a SeisData structure.
Note: Limited functionality; cannot currently handle full SEED files or most
non-data blockettes.

Keywords:
* swap=false::Bool
* v=0::Int
"""
function readmseed(fname::String; swap=false::Bool, v::Int=KW.v)
  S = SeisData(0)
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
  return S
end

"""
    readmseed!(S, fname)

Read file `fname` into `S` big-Endian mini-SEED format.
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
