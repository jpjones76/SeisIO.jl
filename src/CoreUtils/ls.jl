function listfiles(d::String, p::AbstractString)
  F = readdir(d)
  S = split(p, '*', keepempty=true)

  # Exact string
  if length(S) == 1
    filter!(j->isequal(j, S[1]), F)
  else
    # start
    filter!(k->startswith(k, S[1]), F)
    # middle
    length(S) > 2 && [filter!(k->occursin(S[i], k), F) for i = 2:length(S)-1]
    # end
    filter!(k->endswith(k, S[end]), F)
  end
  return F
end

function ls(s::String)
  if Sys.iswindows() == false
    # works in v >= 0.5.2
    return filter(x -> !isempty(x), map(String, split(read(`bash -c "ls -1 $s"`, String), "\n")))
  else
    isdir(s) && return readdir(s)
    safe_isfile(s) && return(Array{String,1}([s]))

    # The syntax below takes advantage of the fact that realpath in Windows
    # doesn't test for existence and hence won't break on wildcards.
    c = Char['/', '\\']
    K = split(realpath(s), c)

    if length(K) == 1
      return listfiles(pwd(), K[1])
    else
      F = Array{String,1}(K[1:1])
      for i = 1:length(K)-1
        β = Array{String,1}()
        for j = 1:length(F)
          α = listfiles(string(F[j],"/"), K[i+1])
          append!(β, String[string(F[j],"/",α[k]) for k=1:length(α)])
        end
        F = deepcopy(β)
      end
      return F
    end
    # The two-liner below works about as well as "dir" ever has
    # which is to say, not robustly. Nonetheless, it can work.
    # s = replace(s, "/" => "\\")
    # return map(String, filter(x -> !isempty(x), split(read(`cmd /c dir /b $s`, String), "\r\n")))
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

# WORKING IN LINUX AS OF 2017-07-03
# ls("/data2/Research")
# ls("/data2/Research/Yellowstone/*.txt")
# cd("/data2/Research/DLP"); ls("*seis")
# cd("/data2/Research/DLP"); ls("poo.seis")
# cd("/data2/Research/DLP"); ls("dlp.seis")
# ls("/win/Users/Josh/*hist")
