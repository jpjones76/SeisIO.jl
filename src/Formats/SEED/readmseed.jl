export readmseed, readmseed!

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

@doc """
    readmseed(fname[, KWs])

Read mini-SEED file `fname` into a new SeisData structure.

  readmseed!(S, fname[, KWs])

Read mini-SEED file `fname` into existing SeisData structure `S`.

### Supported Keywords
* swap: Byte swap. Set false for no (little-Endian). readmseed should be able
to determinme whether to byte swap automatically; only use this keyword if you
encounter errors. (Default: false)
* v: Verbosity. (Default: 0)
* nx_new: allocate data arrays of length `N` samples for each new channel.
(Default: 86400000) [^a]
* nx_add: increase `S.x[i]` by at least `N` samples when new data are added to
channel `i`. (Default: 360000) [^a]

[^a]: After data read, unused memory is freed by resizing arrays in S.x.

!!! tip

    For best performance, if `n_sm` is the smallest expected number of samples,
and `n_lg` is the largest, set `nx_new = n_sm, nx_add = n_lg-n_sm`. A poor
choice of nx_new and nx_add will dramatically impact performance.

See also: mseed_support
""" readmseed
function readmseed!(S::SeisData, fname::String;
                    swap::Bool=false,
                    v::Int64=KW.v,
                    nx_new::Int64=KW.nx_new,
                    nx_add::Int64=KW.nx_add)
  setfield!(BUF, :swap, swap)

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

@doc (@doc readmseed)
function readmseed(fname::String;
                    swap::Bool=false,
                    v::Int=KW.v,
                    nx_new::Int64=KW.nx_new,
                    nx_add::Int64=KW.nx_add
                  )
  S = SeisData()
  readmseed!(S, fname, swap=swap, v=v, nx_new=nx_new, nx_add=nx_add)
  return S
end
