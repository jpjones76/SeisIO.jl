function get_SampleFiles()
  status = 1
  if Sys.iswindows()
    status = (try
      p = run(`cmd /c svn export https://github.com/jpjones76/SeisIO-TestData/trunk/SampleFiles SampleFiles`)
      0
    catch err
      @warn(string("svn threw error: ", err))
      1
    end)
  else
    status = (try
      p = run(`svn export https://github.com/jpjones76/SeisIO-TestData/trunk/SampleFiles SampleFiles`)
      p.exitcode
    catch err
      @warn(string("svn threw error: ", err))
      println()
      1
    end)
  end
  return status
end
