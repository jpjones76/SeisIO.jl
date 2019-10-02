function get_SampleFiles()
  status = 1
  if Sys.iswindows()
    @warn("Windows svn NYI")
    status = 1
  else
    status = (try
      p = run(`svn export https://github.com/jpjones76/SeisIO-TestData/trunk/SampleFiles SampleFiles`)
      p.exitcode
    catch err
      @warn(string("svn threw error: ", err))
      1
    end)
  end
  return status
end
