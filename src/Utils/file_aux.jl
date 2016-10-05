function lsw(filestr::String)
  d, f = splitdir(filestr)
  i = search(f, '*')
  if !isempty(i)
    ff = f[1:i[1]-1]
    for j = 1:1:length(i)
      ei = j == length(i) ? length(f) : i[j+1]
      ff = join([ff, '.', '*', f[i[j]+1:ei]])
    end
  else
    ff = f
  end
  fff = Regex(ff)
  files = [joinpath(d, j) for j in filter(i -> ismatch(fff,i), readdir(d))]
  return files
end


"""
  (s, c) = chparse(C)

Parse channel file or channel string **C**. **C** must use valid SeedLink
syntax, e.g. C = "GE ISP  BH?.D,NL HGN"; (s, c) = chparse(C).

Outputs:
* s: array of station strings, each formatted "net sta"
* c: array of channel patterns to match
"""
function chparse(C::String)

  # Read C
  if isfile(C)
    ccfg = [strip(j, ['\r','\n']) for j in filter(i -> !startswith(i, ['\#','\*']), open(readlines, C))]
  else
    ccfg = split(C, ',')
  end

  stas = Array{String,1}()
  patts = Array{String,1}()

  # Parse ccfg
  for i = 1:length(ccfg)
    try
      (net, sta, sel) = split(ccfg[i], ' ', limit=3)
      ch = join([sta, net],' ')
      if isempty(sel)
        push!(stas, ch)
        push!(patts, "")
      else
        sel = collect(split(strip(sel), ' '))
        for j = 1:length(sel)
          push!(stas, ch)
          push!(patts, sel[j])
        end
      end
    catch
      (net, sta) = split(ccfg[i], ' ', limit=3)
      push!(stas,net)
      push!(patts,"")
    end
  end

  return (stas, patts)
end
