export ls

# safe_isfile, safe_isdir adapted from https://github.com/JuliaPackaging/BinaryProvider.jl/commit/08a314a225206a68665c6f730d7c3feeda1ba615
# Temporary hack around https://github.com/JuliaLang/julia/issues/26685
function safe_isfile(path)
    try
        return isfile(path)
    catch err
        if typeof(err) <: Base.IOError && err.code == Base.UV_EINVAL
            return false
        end
        rethrow(err)
    end
end

function safe_isdir(path)
    try
        return isdir(path)
    catch err
        if typeof(err) <: Base.IOError && err.code == Base.UV_EINVAL
            return false
        end
        rethrow(err)
    end
end

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
    safe_isdir(s) && return readdir(s)
    safe_isfile(s) && return(Array{String,1}([s]))

    # The syntax below takes advantage of the fact that realpath in Windows
    # doesn't test for existence and hence won't break on wildcards.
    c = Char['/', '\\']
    K = Sys.iswindows() ? split(relpath(s), c) : split(realpath(s), c)

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
ls() = readdir(pwd())
