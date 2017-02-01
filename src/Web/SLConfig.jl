function cfile_parse(C::String; delim=','::Char)
  if isfile(C)
    ccfg = [strip(j, ['\r','\n']) for j in filter(i -> !startswith(i, ['\#','\*']), open(readlines, C))]
  else
    ccfg = split(C, delim, keep=false)
  end
  return map(String, ccfg)
end


"""
  Q = SL_config(C)

Parse channel file or channel string `C`. Here, `Q[:,1]` = station selectors, `Q[:,2]` = pattern selectors.

Q = SL_config(C, delim=d::Char)

Specify a character as the delimiter `d` between channel strings in `C`. Only valid if `C` is a string.

  Q = SL_config(C, fdsn=true::Bool)

Parse channel file or channel string `C` for use with FDSN \& IRIS web requests. `Q` is a string array optimized s.t. looping over each element of `Q` makes all channel requests in `C` in a minimum number of web requests.

When `fdsn=true`, strings in `Q` are formatted "net=NN&sta=ST1,ST2,...&loc=LL&cha=CCC" for direct use with FDSN web requests.

# Examples
```jldoctest
julia> C = "GE ISP  BH?.D,NL HGN"; Q1 = SL_config(C)
2x2 Array{String,2}:
 "ISP GE"  "??BH?.D"
 "HGN NL"  "?????.?"

julia> C = "GE ISP  BH?.D|NL HGN|UW LON"; Q1 = SL_config(C, delim='|')
3×2 Array{String,2}:
 "ISP GE"  "??BH?.D"
 "HGN NL"  "?????.?"
 "LON UW"  "?????.?"

julia> C = "UW TDH ?????.??;CC HOOD;UW VLL;UW VLM;UW VFP"; Q2 = SL_config(C, fdsn=true, delim=';')
3-element Array{String,1}:
 "net=UW&sta=TDH&loc=??&cha=???"
 "net=CC&sta=HOOD&loc=??&cha=???"
 "net=UW&sta=VLL,VLM,VFP&loc=??&cha=???"
```
"""
function SL_config(C::String; fdsn=false::Bool, delim=','::Char)
  # Read C if a file, else split as a comma-delineated string
  ccfg = cfile_parse(C; delim=delim)

  # Parse C
  R = Array{String,2}(0,5)
  for i = 1:length(ccfg)
    line = split(ccfg[i], ' ', limit=3, keep=false)
    if length(line) == 3
      (net, sta, rest) = line
      P = split(rest,' ', keep=false)
      for pat in P
        (loc, cha, t) = pat_parse(pat)
        R = cat(1, R, [net sta loc cha t])
      end
    elseif length(line) == 2
      (net, sta) = line
      loc = "??"
      cha = "???"
      t = "?"
      R = cat(1, R, [net sta loc cha t])
    else
      error(string("Bad line format: ", line))
    end
  end
  L = size(R,1)
  if fdsn
    # SL_minreq returns a string matrix in the form ["NET" "STA" "LOC" "CHA"]
    minreq!(R)
    L = size(R,1)
    Q = Array{String,1}(L)
    for i = 1:1:L
      Q[i] = string("net=", R[i,1], "&sta=", R[i,2], "&loc=", R[i,3], "&cha=", R[i,4])
    end
    return Q
  else
    # Otherwise simply reformat for use with SeedLink
    Q = Array{String,2}(L,2)
    for i = 1:1:L
      Q[i,1] = join([R[i,2],R[i,1]],' ')
      Q[i,2] = join([join([R[i,3],R[i,4]]),R[i,5]],'.')
    end
    return Q
  end
end

# From "documentation": “LL”, “.T”, and “LLCCC.” can be omitted, meaning “any”.
# It is also possible to use “?” in place of L and C.
#
# Allowed: LLCCC.T, LLCCC, CCC.T, CCC, T
function pat_parse(pat)
  loc = "??"
  cha = "???"
  t = "?"
  if contains(pat, ".")
    (lc,t) = split(pat, '.', limit=2, keep=false)
    if length(lc) >= 5
      loc = lc[1:2]           # LLCCC.T
      cha = lc[3:5]
    elseif length(lc) == 3
      cha = lc                # CCC.T
    end
  elseif length(pat) == 1
    t = pat                   # T
  elseif length(pat) == 3
    cha = pat                 # CCC
  elseif length(pat) >= 5
    loc = pat[1:2]            # LLCCC
    cha = pat[3:5]
  end
  return (loc, cha, t)
end
