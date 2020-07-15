function info_dump(D::Dict{String, Any}, level::Int)
  p = 38-level
  w = max(40, displaysize(stdout)[2]-40)
  K = sort(collect(keys(D)))
  subdicts = String[]

  for k in K
    if isa(D[k], Dict{String, Any})
      push!(subdicts, k)
    else
      println(lpad(k, p), ": ", strip(string(D[k])))
    end
  end

  for k in subdicts
    (level > 0) && print(" "^(2*level))
    printstyled(k * "\n", color=level+1, bold=true)
    info_dump(D[k], level+1)
  end
  return nothing
end
info_dump(S::NodalData) = (printstyled(":info\n", color=14, bold=true); info_dump(S.info, 1))
