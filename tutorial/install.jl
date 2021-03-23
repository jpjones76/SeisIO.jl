import SeisIO: get_svn
path = joinpath(Base.source_dir(),"../test/TestHelpers/0_check_deps.jl")
include(path)
include("./check_data.jl")
pkg_check(["DSP", "SeisIO", "IJulia"])
get_svn("https://github.com/jpjones76/SeisIO-TestData/trunk/Tutorial", "DATA")

using IJulia
jupyterlab(dir=joinpath(dirname(dirname(pathof(SeisIO))),"tutorial"))
