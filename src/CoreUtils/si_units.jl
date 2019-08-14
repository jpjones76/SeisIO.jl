export si_units

function to_superscript(u::Array{UInt32,1}, i::Int64)
  (i ≥ length(u)) && error("bad units String!")
  j = i
  while j < length(u)
    j = j+1
    if u[j] == 0x00000032 # ^2
      u[j] = 0x000000b2
    elseif u[j] == 0x00000033 # ^3
      u[j] = 0x000000b3
    elseif u[j] == 0x00000030 # ^0
      u[j] = 0x00002070
    elseif u[j] == 0x00000031 # ^1
      u[j] = 0x000000b9
    elseif u[j] in 0x00000034:0x00000039 #^4-^9
      u[j] = 0x00002070 + u[j] - 0x00000030
    else # end of digits reached; break
      break
    end
  end
  return j-1
end

# Home of a string function to convert units to SI
function si_units(str::String)
  u = Array{UInt32, 1}(undef, length(str))
  i = 1
  j = 0
  while j < length(str)
    j = nextind(str, j)
    u[i] = UInt32(str[j])
    i = i + 1
  end

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
      # println("setting a denominator")
    end
  end
  if d
    j = m
    f = false
    while j > 1
      j -= 1
      if (u[j] in 0x00000061:0x0000007a) || (u[j] in 0x00000041:0x0000005a)
        # println("alphabetical unit sequence")
        # start of alphabetical unit sequence
        if f == false
          f = true
        end
      elseif f == true
        # println("setting denominator here")
        insert!(u, j, 0x0000002f)
        break
      end
    end
  end
  # println(stdout, String(Char.(u)))

  i = 0
  k = Int64[]
  while i < length(u)
    i = i + 1
    # println("i = ", i, ", u[", i, "] = ", u[i], ", c = ", Char(u[i]))

    if u[i] == 0x0000005e && i < length(u)
      # delete "^"
      push!(k, i)

      if u[i+1] == 0x0000002d
        # delete "- after ^"
        i = i+1
        push!(k, i)
      end

      # ^N, ^-N will always be 0x5e followed by (0x2d and) a number
      i = to_superscript(u, i)

    elseif u[i] == 0x0000002a && i+1 < length(u)
      if u[i+1] == 0x0000002a
        # **N is 0x2a, 0x2a followed by a number

        push!(k, i)
        push!(k, i+1)
        if u[i+2] == 0x0000002d
          # delete "- after ^"
          i = i+1
          push!(k, i+1)
        end

        i = to_superscript(u, i+1)

      else

        # Correct for multiplication represented by *
        u[i] = 0x00000020
      end

    elseif u[i] in (0x0000002f, 0x00000020)

      # delete whitespace after a / or space
      j = i
      while j < length(u)
        j = j+1
        if u[j] == 0x00000020
          # println("whitespace after /")
          push!(k, j)
        else
          i = j-1
          break
        end
      end

    end
  end
  deleteat!(u, k)
  return String(Char.(u))
end
