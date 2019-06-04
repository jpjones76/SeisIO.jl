export ls, regex_find, safe_isdir, safe_isfile

# safe_isfile, safe_isdir adapted from https://github.com/JuliaPackaging/BinaryProvider.jl/commit/08a314a225206a68665c6f730d7c3feeda1ba615
# Temporary hack around https://github.com/JuliaLang/julia/issues/26685
function safe_isfile(path::String)
  try
    return isfile(path)
  catch err
    return false
  end
end

function safe_isdir(path::String)
  try
    return isdir(path)
  catch err
    return false
  end
end

"""
    find_regex(path::String, r::Regex)

OS-agnostic equivalent to Linux `find`. First argument is a path string, second is a Regex. File strings are postprocessed using Julia's native PCRE Regex engine.

"""
function regex_find(path::String, r::Regex)
  path = realpath(path)

  if Sys.iswindows()
    s = filter(x -> !(isempty(x) || x == path),
      String.(split(read(
          `powershell -Command "(Get-ChildItem -Path $path -File -Force -Recurse).FullName"`,
          String), "\r\n"))
              )
    s = [replace(i, sep => "/") for i in s]
    s2 = s[findall([occursin(r, f) for f in s])]

  else
    s = filter(x -> !(isempty(x) || x == path),
                String.(split(read(
                  `sh -c "find $path -type f"`,
                  String), "\n"))
              )

    s2 = String[]
    m = length(path) + 2
    for (i,f) in enumerate(s)
      s1 = f[m:end]
      if occursin(r, s1)
        push!(s2, f)
      end
    end
  end

  # Julia doesn't seem to handle regex searches in shell
  return sort(s2)
end

@doc """
    ls(str::String)

Similar functionality to Bash ls -1 with OS-agnostic output. Accepts wildcards.
Always returns full path and file name.

    ls()

Return full path and file name of files in current working directory.
""" ls
function ls(s::String)
  safe_isfile(s) && return [realpath(s)]
  safe_isdir(s) && return [joinpath(realpath(s), i) for i in readdir(s)]

  (p,f) = splitdir(s)

  if any([occursin(i, s) for i in regex_chars]) || occursin("*", p) || f == "*"
    # We're actually going to start at the highest-level directory that is
    # uniquely specified, so rather than starting at p from splitdir...
    fpat = String.(split(s, "*"))
    path, ff = splitdir(fpat[1])
    if isempty(ff)
      popfirst!(fpat)

      #= ...but this can leave us with an empty fpat and regex for that
      isn't standardized, so... =#
      if isempty(fpat) || fpat == [""]
        fpat = [".*"]
      end
    else
      fpat[1] = ff
    end

    # In case of empty path ... ?
    if isempty(path)
      path = "."
    end

    # So we're going to check for matches on all but the first m of each string:
    ff = join(fpat, ".*")
    mpat = Regex(ff * "\$")

    s1 = regex_find(path, mpat)
    if s1 == nothing
      s1 = []
    end
  else
    s1 = try
      glob(f,p)
    catch
      String[]
    end

    # DND DND DND DND DND
    # Control for odd behavior of glob in Linux
    if !(isempty(s1))
      if isempty(p); p = "." ; end
      for (i,s) in enumerate(s1)
        f = splitdir(s)[2]
        s1[i] = joinpath(realpath(p), f)
      end
    end
    # DND DND DND DND DND
  end
  return s1
end

ls() = [joinpath(realpath("."), i) for i in readdir(pwd())]
