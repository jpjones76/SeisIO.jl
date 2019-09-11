printstyled("  dataless SEED\n", color=:light_green)
redirect_stdout(out) do
  metafile = path*"/SampleFiles/CC.dataless"
  S = read_meta("dataless", metafile, v=3,
                s="2008-01-01T00:00:00",
                t="2008-02-01T00:00:00",
                units=true)

  files = ls(path*"/SampleFiles/SEED/*.dataless")
  for i in files
    S = read_meta("dataless", i, v=0, units=false)
    S = read_meta("dataless", i, v=1, units=false)
    S = read_meta("dataless", i, v=2, units=false)
    S = read_meta("dataless", i, v=3, units=false)
    S = read_meta("dataless", i, v=3, units=true)
  end
end
