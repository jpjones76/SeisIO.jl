using Test

printstyled("  read_meta equivalencies\n", color=:light_green)
printstyled("    full (XML, RESP, dataless)\n", color=:light_green)

S1 = read_meta("sxml", path*"/SampleFiles/fdsnws-station_2019-09-11T06_26_58Z.xml", s="2016-01-01T00:00:00", msr=true)
S2 = read_meta("resp", path*"/SampleFiles/JRO.resp", units=true)
S3 = read_meta("dataless", path*"/SampleFiles/SEED/CC.dataless", s="2016-01-01T00:00:00", units=true)[56:58]
S4 = read_meta("sacpz", path*"/SampleFiles/JRO.sacpz")

C = Array{Char,2}(undef, 10, 3)
fill!(C, ' ')
SA = Array{String, 2}(undef, 10, 3)
for k = 1:3
  fstr = ""
  n = 0
  # println("    ===== ", S1.id[k], " =====")
  R1 = S1.resp[k]
  R2 = S2.resp[k]
  R3 = S3.resp[k]
  for f in fieldnames(MultiStageResp)
    fstr = uppercase(String(f))
    n += 1
    f1 = getfield(R1, f)
    f2 = getfield(R2, f)
    f3 = getfield(R3, f)
    t = min(isequal(f1, f2), isequal(f1, f3))
    if t
      C[n,k] = '='
    else

      # Check for same size, type
      L = length(f1)
      if L != length(f2) || L != length(f3)
        C[n,k] = 'f'
        continue
      elseif typeof(f1) != typeof(f2) || typeof(f1) != typeof(f3)
        C[n,k] = 'f'
        continue
      end

      # Check for approximately equal fields
      T = falses(L)
      for i = 1:L
        i1 = getindex(f1, i)
        i2 = getindex(f2, i)
        i3 = getindex(f3, i)
        t2 = min(isequal(i1, i2), isequal(i1, i3))
        if t2 == true
          T[i] = true
        else
          T1 = typeof(i1)
          if T1 != typeof(i2) || T1 != typeof(i3)
            C[n,k] = 'f'
            break

          # Easyfor a bitstype
          elseif isbitstype(T1)
            if isapprox(i1, i2) && isapprox(i1, i3)
              C[n,k] = '≈'
              T[i] = true
              continue
            end
          else
            FF = fieldnames(T1)

            # Only possible for a String in these Types
            if isempty(FF)
              C[n,k] = 'f'

            # Check for approximately equal subfields
            else
              TT = falses(length(FF))
              for (j,g) in enumerate(FF)
                j1 = getfield(i1, g)
                j2 = getfield(i2, g)
                j3 = getfield(i3, g)

                # Dimension mismatch
                if !(length(j1) == length(j2) == length(j3))
                  C[n,k] = 'f'

                # True mismatch
                elseif min(isapprox(j1, j2), isapprox(j1, j3)) == false
                  C[n,k] = 'f'

                # Approx. equality
                else
                  TT[j] = true
                end
              end

              # If they're all approximate, set T[i] to true
              if minimum(TT) == true
                T[i] = true
              end
            end
          end
        end
      end

      # If they're all approximate, set C[n,k] to ≈
      if minimum(T) == true
        C[n,k] = '≈'
      end
    end
    SA[n,k] = (k == 1 ? lpad(fstr * ": ", 12) : "") * lpad(C[n,k], 5)
    @test C[n,k] in ('≈', '=')
  end
end
println("")
println(" "^12,
        lpad(S1.id[1][end-3:end], 6),
        lpad(S1.id[2][end-3:end], 6),
        lpad(S1.id[3][end-3:end], 6))
println(" "^12, "|", "="^5, "|", "="^5, "|", "="^5)
for i = 1:size(SA,1)
  println(join(SA[i,:], " "))
end
println("")

printstyled("    one-stage (SACPZ, XML)\n", color=:light_green)
S1 = read_meta("sxml", path*"/SampleFiles/fdsnws-station_2019-09-11T06_26_58Z.xml", s="2016-01-01T00:00:00", msr=false)
S4 = read_meta("sacpz", path*"/SampleFiles/JRO.sacpz")
K = Array{Char,2}(undef, 3, 3)
fill!(K, ' ')
SA = Array{String, 2}(undef, 3, 3)
for k = 1:3
  n = 0
  R1 = S1.resp[k]
  R2 = S4.resp[k]
  for f in fieldnames(PZResp)
    fstr = uppercase(String(f))
    (f == :f0) && continue # SACPZ lacks f0 for some reason
    n += 1
    f1 = getfield(R1, f)
    f2 = getfield(R2, f)
    t = isequal(f1, f2)
    if t == true
      K[n,k] = '='
    else

      # Check for same size, type
      L = length(f1)
      if L != length(f2)
        K[n,k] = 'f'
        continue
      elseif typeof(f1) != typeof(f2)
        K[n,k] = 'f'
        continue
      elseif isapprox(f1, f2)
        K[n,k] = '≈'
      end
    end
    @test K[n,k] in ('≈', '=')
    SA[n,k] = (k == 1 ? lpad(fstr * ": ", 12) : "") * lpad(K[n,k], 5)
  end
end
println("")
println(" "^12,
        lpad(S1.id[1][end-3:end], 6),
        lpad(S1.id[2][end-3:end], 6),
        lpad(S1.id[3][end-3:end], 6))
println(" "^12, "|", "="^5, "|", "="^5, "|", "="^5)
for i = 1:size(SA,1)
  println(join(SA[i,:], " "))
end
println("")
