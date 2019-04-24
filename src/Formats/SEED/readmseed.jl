export readmseed, readmseed!

function seed_cleanup!(S::SeisData, SEED::SeedVol)
  trunc_x!(S)
  fill!(getfield(SEED, :hdr_old), zero(UInt8))
  setfield!(SEED, :r1_old, zero(Int16))
  setfield!(SEED, :r2_old, zero(Int16))
  return nothing
end

function parsemseed!(S::SeisData, sid::IO, v::Int64, nx_new::Int64, nx_add::Int64)
  while !eof(sid)
    parserec!(S, SEED, sid, v, nx_new, nx_add)
  end
  seed_cleanup!(S, SEED)
  return S
end

"""
    readmseed(fname[, KWs])

Read mini-SEED file `fname` into a new SeisData structure.

  readmseed!(S, fname[, KWs])

Read mini-SEED file `fname` into existing SeisData structure `S`.

### Keywords
* swap: Byte swap. Set false for no (little-Endian). readmseed should be able
to determinme whether to byte swap automatically; only use this keyword if you
encounter errors. (Default: false)
* v: Verbosity. (Default: 0)
* nx_new: allocate data arrays of length `N` samples for each new channel.
(Default: 86400000) [^a]
* nx_add: increase `S.x[i]` by at least `N` samples when new data are added to
channel `i`. (Default: 360000) [^a]

[^a]: After data read, unused memory is freed by resizing arrays in S.x; thus, for best performance, set nx_new ≥ the longest expected time-series length in samples.
"""
function readmseed!(S::SeisData, fname::String;
                    swap=false::Bool,
                    v::Int=KW.v,
                    nx_new::Int64=KW.nx_new,
                    nx_add::Int64=KW.nx_add)
  setfield!(SEED, :swap, swap)

  if safe_isfile(fname)
    fid = open(fname, "r")
    skip(fid, 6)
    (findfirst(isequal(read(fid, Char)), "DRMQ") > 0) || error("Scan failed due to invalid file type")
    seek(fid, 0)
    parsemseed!(S, fid, v, nx_new, nx_add)
    close(fid)
  else
    error("Invalid file name!")
  end
  return nothing
end
readmseed(fname::String;
          swap=false::Bool,
          v::Int=KW.v,
          nx_new::Int64=KW.nx_new,
          nx_add::Int64=KW.nx_add
          ) = (S = SeisData();
               readmseed!(S, fname, swap=swap, v=v, nx_new=nx_new, nx_add=nx_add);
               return S)
