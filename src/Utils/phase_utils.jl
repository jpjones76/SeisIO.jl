# =============================================================
# Utility functions
sa_prune!(S::Union{Array{String,1},Array{SubString{String},1}}) = (deleteat!(S, findall(isempty, S)); return S)
parse_pcat(pcat::Array{String,2}) = (pcat[:,3], map(Float64, [Meta.parse(i) for i in pcat[:,4]]))
pcat_start(pcat::Array{String,2}) = findmin([Meta.parse(i) for i in pcat[:,4]])[1]
pcat_end(pcat::Array{String,2}) = findmax([Meta.parse(i) for i in pcat[:,4]])[1]

function phase_time(pha::String, pcat::Array{String,2})
    j = findall(pcat[:,3] .== pha)
    if isempty(j)
        error(string("Phase ", pha, " not found in phase list!"))
    else
        i = j[1]
        if length(j) > 1
            @warn(string("Phase ", pha, " appears multiple times in phase list! Only using first occurrence in phase list."))
        end
        return Float64(Meta.parse(pcat[j[1], 4]))
    end
end

function next_phase(pha::String, pcat::Array{String,2})
  if isempty(pha) || pha == "ttall"
    pha = "P"
  end
  (phases, τ) = parse_pcat(pcat)
  j = findfirst(phases.==pha)
  if isempty(j)
    j = findfirst(phases.==(pha*"diff"))
    isempty(j) && error("No such phase!")
  end
  i = τ .- τ[j] .> 0
  tt = τ[i]
  ss = phases[i]
  k = sortperm(tt .- τ[j])[1]
  return ss[k], tt[k]
end

function first_phase(pcat::Array{String,2})
  (phases, τ) = parse_pcat(pcat)
  i = sortperm(τ)[1]
  return phases[i], τ[i]
end
