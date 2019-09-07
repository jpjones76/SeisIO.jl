export units2ucum, validate_units, vucum
# Units issues
# (1) UCUM has not standardized the abbreviations of units used in information technology. For now, use "By" for Bytes and "bit" for bits, cf. https://hl7.org/fhir/2017Jan/valueset-ucum-units.html ; but neither appears in the most recent HL7 UCUM value set.

# Fixing a few common units mistakes that I keep seeing
const units_table = Dict{String,String}(
  "bits/sec" => "bit/s",
  "pascals" => "Pa",
  "degrees" => "deg",
  "reboots" => "{reboots}",
  "percent" => "%",
  "gaps" => "{gaps}",
  "bytes" => "By",
  "cycles" => "{cycles}",
  "counts" => "{counts}",
  "COUNTS" => "{counts}",
  "M**3/M**3" => "m3/m3",
  "M/S" => "m/s",
  "PA" => "Pa",
  "M/M" => "m/m",
  "M/S**2" => "m/s2",
  "M/S/S" => "m/s2",
  "M" => "m"
  )
fix_units(s::AbstractString) = get(units_table, s, s)

function strip_exp!(k::Array{Int64,1}, u::Array{UInt32,1}, j::Int64)
  (j == length(u)) && return j
  i = j

  # ^+, ^-, **+, **-
  if u[i] == 0x0000002b || u[i] == 0x0000002d
    push!(k, i)
    i = i+1
  end

  if i ≤ length(u)
    while i < length(u)
      if u[i] in 0x00000030:0x00000039 #'0':'9'
        i = i+1
      else # end of digits reached; break
        break
      end
    end
    # end
  end
  return i
end

# Home of a string function to convert units to SI
"""
    units2ucum(str)

Convert unit string `str` to UCUM syntax.

Rules applied to strings:
* Deletes "power" notation for integer powers: (^, ^+, ^-, **, **+, **-)
* Deletes "power" notation for special cases: (^+1, ^-1, **+1, **-1)
* Replaces multiplication symbols (*, ⋅, ×) with .
"""
function units2ucum(str::String)
  u = [UInt32(str[i]) for i in eachindex(str)]

  # set denominator position if '-' && no '/' to before the last alphabetical sequence
  # preceding
  m = 0
  d = false
  for i = 1:length(u)
    if u[i] == 0x0000002f
      d = false
      break
    elseif u[i] == 0x0000002d
      if m == 0
        m = i
      end
      d = true
    end
  end
  if d
    j = m
    f = false
    while j > 1
      j -= 1
      if (u[j] in 0x00000061:0x0000007a) || (u[j] in 0x00000041:0x0000005a)
        # start of alphabetical unit sequence
        if f == false
          f = true
        end
      elseif f == true
        insert!(u, j, 0x0000002f)
        break
      end
    end
  end

  i = 1
  k = Int64[]
  while i < length(u)

    # expressions that start with ^
    if u[i] == 0x0000005e
      #= Delete:
          ^
          ^+
          ^-
          ^+1
          ^-1
      =#
      push!(k, i)
      i = strip_exp!(k, u, i+1)

    # expressions that start with *
    elseif u[i] == 0x0000002a
      if i+1 ≤ length(u)
        #= Delete:
            **
            **+
            **-
            **+1
            **-1
        =#
        if u[i+1] == 0x0000002a
          push!(k, i)
          push!(k, i+1)
          i = strip_exp!(k, u, i+2)
        else
          # Change to "."
          u[i] = 0x0000002e
          if i > 1
            if u[i-1] == 0x0000002f
              push!(k, i)
            end
          end
          i = i+1
        end
      end

    # expressions that start with /, (space)
    elseif u[i] in (0x0000002f, 0x00000020)
      # delete whitespace after a / or space
      j = i
      while j < length(u)
        j = j+1
        if u[j] in (0x000000d7, 0x00000020, 0x0000002e, 0x000022c5)
          push!(k, j)
        else
          i = j-1
          break
        end
      end
      i = i+1
    else
      i = i+1
    end
  end
  deleteat!(u, k)

  # Replace multiplication operators with periods
  for i = 1:length(u)
    if u[i] in (0x000000d7, 0x00000020, 0x000022c5)
      u[i] = 0x0000002e
    end
  end

  # Get the position of the "/", if one exists
  m = 0
  for i = 1:length(u)
    if u[i] == 0x0000002f
      m = i
      break
    end
  end

  if m > 0
    k = Int64[]

    # delete "." in "./"
    if m > 1
      if u[m-1] == 0x0000002e
        push!(k, m-1)
      end
    end

    # delete all powers of "1" after the /
    for i = m+1:length(u)
      if u[i] == 0x00000031
        if i == length(u)
          push!(k, i)
          break
        elseif (u[i+1] in 0x00000030:0x00000039) == false
          push!(k, i)
        end
      end
    end

    deleteat!(u, k)
  end
  return String(Char.(u))
end

"""
    vucum(str::String)

Test whether `str` is a valid UCUM unit string.
"""
function vucum(str::String)
  rstr = identity(str)
  if any([occursin(c, rstr) for c in ('%', '^', '[', ']', '{', '}')])
    rstr = replace(rstr, "%" => "%25")
    rstr = replace(rstr, "^" => "%5E")
    rstr = replace(rstr, "[" => "%5B")
    rstr = replace(rstr, "]" => "%5D")
    rstr = replace(rstr, "{" => "%7B")
    rstr = replace(rstr, "}" => "%7D")
  end
  url = "https://ucum.nlm.nih.gov/ucum-service/v1/isValidUCUM/" * rstr
  tf = try
    req = request("GET", url)
    b = String(req.body)
    if b == "true"
      true
    else
      false
    end
  catch err
    @warn(string("Error thrown for unit string: ", str))
    false
  end
  return tf
end

"""
    validate_units(S::GphysData)

Test whether unit strings in S.units are valid under the UCUM standard.

    validate_units(C::GphysChannel)

Test whether C.units is valid under the UCUM standard.
"""
function validate_units(S::GphysData)
  isv = falses(S.n)
  for i = 1:S.n
    isv[i] = vucum(S.units[i])
  end
  return isv
end

validate_units(C::GphysChannel) = vucum(C.units)
