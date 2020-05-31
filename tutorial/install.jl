using IJulia
import SeisIO: get_svn
path = Base.source_dir()
include(path * "../test/TestHelpers/0_check_deps.jl")
pkg_check(["DSP", "SeisIO", "IJulia"])
get_svn("https://github.com/jpjones76/SeisIO-TestData/trunk/Tutorial", "DATA")
jupyterlab(dir=pwd())
