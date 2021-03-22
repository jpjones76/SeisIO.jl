# Packages that throw "not installed" error on upgrade: Compat, DSP, HDF5
using Pkg
function pkg_check(pkgs::Array{String,1})

  # why would you deprecate something this useful?
  if VERSION >= v"1.4"
    installs = Dict{String, VersionNumber}()
    for (uuid, dep) in Pkg.dependencies()
        dep.is_direct_dep || continue
        dep.version === nothing && continue
        installs[dep.name] = dep.version
    end
  else
    installs = Pkg.installed()
  end

  for p in pkgs
    if get(installs, p, nothing) == nothing
      @warn(string(p * " not found! Installing."))
      Pkg.add(p)
    else
      println(p * " found. Not installing.")
    end
  end
  return nothing
end
pkg_check(["DSP", "HDF5"])
