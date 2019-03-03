fs_range = exp10.(range(-6, stop=4, length=50))
fc_range = exp10.(range(-4, stop=2, length=20))

for fs in fs_range
  for fc in fc_range
    getbandcode(fs, fc=fc)
  end
end
