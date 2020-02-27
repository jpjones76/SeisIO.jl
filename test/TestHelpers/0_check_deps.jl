# Packages that throw "not installed" error on upgrade: Compat, DSP, HDF5
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
pkg_check(["DSP", "HDF5"])
