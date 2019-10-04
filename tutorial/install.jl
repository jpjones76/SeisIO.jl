using Pkg
function pkg_check(pkgs::Array{String,1})
  for p in pkgs
    if get(Pkg.installed(), p, nothing) == nothing
      Pkg.add(p)
    else
      println(p * " found, not installing.")
    end
  end
  return nothing
end
pkg_check(["Dates", "DSP", "SeisIO", "IJulia"])
using IJulia
import SeisIO: get_svn
get_svn("https://github.com/jpjones76/SeisIO-TestData/trunk/Tutorial", "DATA")
jupyterlab(dir=pwd())
