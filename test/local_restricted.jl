restr_path = Base.source_dir() * "/SampleFiles/Restricted/"
if isdir(restr_path) == false
  for i in ["/data/", "/data2"]
    restr_dir = i * "SeisIO-TestFiles/SampleFiles/Restricted"
    if isdir(restr_dir)
      try
        run(`cp -r $restr_dir SampleFiles/`)
        println("copied SampleFiles/Restricted/ from ", i)
      catch err
        @warn(err)
      end
    end
  end
else
  println("nothing to copy, SampleFiles/Restricted/ exists")
end
