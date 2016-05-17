"""
    rlennasc(fname)

Read Lennartz-type ASCII file fname with pseudo-header info in first line.
"""

function rlennasc(fname::ASCIIString)
  S = SeisObj()
  fid = open(fname, "r")
  h = split(readline(fid))
  ts = 0

  sta = replace(h[3],"\'", "")
  S.fs = 1000/parse(h[5])
  ts = Dates.datetime2unix(DateTime(join([h[8],"T",h[9]])))

  cmp = split(fname,'.')[end]
  x = readdlm(fid)
  close(fid)

  S.name = join([sta, cmp], '.')
  S.id = join(["", sta, "", cmp], '.')
  S.t = map(Float64, [0 ts; length(S.x) 0])
  S.x = x[:,1]
  S.src = "lennartz_ascii"
  return S
end
