if Sys.iswindows()
  println("cmd /c deltree SampleFiles/")
  run(`cmd /c deltree SampleFiles/`)
else
  println("rm -rf SampleFiles/")
  run(`rm -rf SampleFiles/`)
end
