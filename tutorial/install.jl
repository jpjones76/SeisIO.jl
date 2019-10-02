using Pkg
Pkg.add(["Dates", "DSP", "SeisIO", "IJulia"])
using IJulia

# Check that the tutorial files exist
tutorial_dir =  dirname(pathof(SeisIO))*"/../tutorial/DATA"
if isdir(tutorial_dir)
  println("tutorial/ exists; not downloading.")
else
  println("dowloading tutorial data (17 MB)...")
  if Sys.iswindows()
    error("NYI")
  else
    p = (run(`svn export https://github.com/jpjones76/SeisIO-TestData/trunk/Tutorial DATA`)).exitcode
    (p == 0) || error("error downloading tutorial/!")
  end
end

jupyterlab(dir=pwd())
