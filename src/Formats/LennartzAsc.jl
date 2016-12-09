"""
    rlennasc(fname)

Read Lennartz-type ASCII file fname with pseudo-header info in first line.
"""

function rlennasc(f::String)
  fname = realpath(f)
  S = SeisChannel()
  fid = open(fname, "r")
  h = split(readline(fid))
  ts = 0

  sta = replace(h[3],"\'", "")
  S.fs = 1000/parse(h[5])
  ts = round(Int, Dates.datetime2unix(DateTime(join([h[8],"T",h[9]])))/μs)

  cmp = split(fname,'.')[end]
  x = readdlm(fid)
  close(fid)

  S.name = join([sta, cmp], '.')
  S.id = join(["", sta, "", cmp], '.')
  S.t = [1 ts; length(S.x) 0]
  S.x = x[:,1]
  S.src = join(["rlennasc",timestamp(),realpath(f)],',')
  return S
end
