function listfiles(d::String, p::AbstractString)
  F = readdir(d)
  S = split(p, '*', keep=true)

  # Exact string
  if length(S) == 1
    filter!(j->isequal(j, S[1]), F)
  else
    # start
    filter!(k->startswith(k, S[1]), F)
    # middle
    length(S) > 2 && [filter!(k->contains(k, S[i]), F) for i = 2:1:length(S)-1]
    # end
    filter!(k->endswith(k, S[end]), F)
  end
  return F
end

function ls(s::String)
  isdir(s) && return readdir(s)
  isfile(s) && return(Array{String,1}([s]))
  c = Char['/', '\\']
  K = split(realpath(s), c)

  if length(K) == 1
    return listfiles(pwd(), K[1])
  else
    F = Array{String,1}(K[1:1])
    for i = 1:1:length(K)-1
      β = Array{String,1}()
      for j = 1:1:length(F)
        α = listfiles(string(F[j],"/"), K[i+1])
        append!(β, String[string(F[j],"/",α[k]) for k=1:1:length(α)])
      end
      F = deepcopy(β)
    end
    return F
  end
end
ls() = readdir(pwd())


# Tests
# Windows
# ls("F:\\Research")
# ls("F:/Research/Yellowstone/*.txt")
# cd("F:/Research/DLP"); ls("*seis")
# cd("F:/Research/DLP"); ls("poo.seis")
# cd("F:/Research/DLP"); ls("dlp.seis")
# ls("C:\\Users\\Josh\\*hist")
