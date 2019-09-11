using Test

printstyled("  meta-data reader equivalence:\n", color=:light_green)
printstyled("    full responses:\n", color=:light_green)

S1 = read_meta("sxml", path*"/SampleFiles/fdsnws-station_2019-09-11T06_26_58Z.xml", s="2016-01-01T00:00:00", msr=true)
S2 = read_meta("resp", path*"/SampleFiles/JRO.resp", units=true)
S3 = read_meta("dataless", path*"/SampleFiles/CC.dataless", s="2016-01-01T00:00:00", units=true)[56:58]
S4 = read_meta("sacpz", path*"/SampleFiles/JRO.sacpz")

C = Array{Char,2}(undef, 10, 3)
fill!(C, ' ')
for k = 1:3
  n = 0
  println("    ===== ", S1.id[k], " =====")
  R1 = S1.resp[k]
  R2 = S2.resp[k]
  R3 = S3.resp[k]
  for f in fieldnames(MultiStageResp)
    n += 1
    f1 = getfield(R1, f)
    f2 = getfield(R2, f)
    f3 = getfield(R3, f)
    t = min(isequal(f1, f2), isequal(f1, f3))
    if t == true
      C[n,k] = 't'
      str = string("      ", uppercase(String(f)), ": =\n")
    else
      str = string("      ", uppercase(String(f)), ": f\n")

      # Check for same size, type
      L = length(f1)
      if L != length(f2) || L != length(f3)
        println(str, "Inequal lengths!")
        C[n,k] = 'f'
        continue
      elseif typeof(f1) != typeof(f2) || typeof(f1) != typeof(f3)
        println(str, "Wrong types!")
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
            str *= string(" "^4, i, ": Type mismatch!\n")
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
              str *= string(" "^4, i, ": !=(", i1 == nothing ? repr(i1) : i1,
                                          ", ", i2 == nothing ? repr(i2) : i2,
                                          ", ", i3 == nothing ? repr(i3) : i3,
                                          ")\n")

            # Check for approximately equal subfields
            else
              TT = falses(length(FF))
              for (j,g) in enumerate(FF)
                j1 = getfield(i1, g)
                j2 = getfield(i2, g)
                j3 = getfield(i3, g)

                # Dimension mismatch
                if !(length(j1) == length(j2) == length(j3))
                  str *= string(" "^4, g, ": Dimensions don't match!\n")
                  C[n,k] = 'f'

                # True mismatch
                elseif min(isapprox(j1, j2), isapprox(j1, j3)) == false
                  str *= string(" "^4, g, ": !=(", j1 == nothing ? repr(j1) : j1,
                                ", ", j2 == nothing ? repr(j2) : j2,
                                ", ", j3 == nothing ? repr(j3) : j3,
                                ")\n")
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
            continue
          end
        end
      end

      # If they're all approximate, set C[n,k] to ≈
      if minimum(T) == true
        str = "      " * uppercase(String(f)) * ": ≈\n"
        C[n,k] = '≈'
      end
    end
    printstyled(str)
  end
  @test C[n,k] in ('≈', 't')
end

printstyled("    one-stage responses:\n", color=:light_green)
S1 = read_meta("sxml", path*"/SampleFiles/fdsnws-station_2019-09-11T06_26_58Z.xml", s="2016-01-01T00:00:00", msr=false)
S4 = read_meta("sacpz", path*"/SampleFiles/JRO.sacpz")
K = Array{Char,2}(undef, 3, 3)
fill!(K, ' ')
for k = 1:3
  n = 0
  println("    ===== ", S1.id[k], " =====")
  R1 = S1.resp[k]
  R2 = S4.resp[k]
  for f in fieldnames(PZResp)
    (f == :f0) && continue # SACPZ lacks f0 for some reason
    n += 1
    f1 = getfield(R1, f)
    f2 = getfield(R2, f)
    t = isequal(f1, f2)
    if t == true
      K[n,k] = 't'
      str = string("      ", uppercase(String(f)), ": =\n")
    else
      str = string("      ", uppercase(String(f)), ": f\n")

      # Check for same size, type
      L = length(f1)
      if L != length(f2)
        println(str, "Inequal lengths!")
        K[n,k] = 'f'
        continue
      elseif typeof(f1) != typeof(f2)
        println(str, "Wrong types!")
        K[n,k] = 'f'
        continue
      elseif isapprox(f1, f2)
        K[n,k] = '≈'
      end
    end
    printstyled(str)
  end
  @test K[n,k] in ('≈', 't')
end
