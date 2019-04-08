printstyled("  Unique memory allocation of SeisData objects\n", color=:light_green)
nx = 1024

S = SeisData(2)
for i=1:S.n
  # Check arrays of same type
  @test pointer_from_objref(S.loc[i]) != pointer_from_objref(S.x[i])
  @test pointer_from_objref(S.gain) != pointer_from_objref(S.fs)
end

for i in datafields
  v = getfield(S,i)
  for j in datafields
    if i != j
      @test pointer_from_objref(getfield(S,i)) != pointer_from_objref(getfield(S,j))
    end
  end
end

# Manually set all fields in the stupidest way possible
S.id[1] *= "...YYY"
S.name[1] *= "New Station"
append!(S.loc[1], zeros(Float64,3))
S.fs[1] += 100.0
S.gain[1] *= 2.0
S.resp[1] = [S.resp[1]; [0.0+0.0*im 1.0+1.0*im; 0.0+0.0*im 1.0-1.0*im]]
S.units[1] *= "Unknown"
S.src[1] *= "www"
append!(S.notes[1], ["sadfasgasfg","kn4ntl42ntlk4n"])
S.misc[1]["P"] = 2.0
S.t[1] = [S.t[1]; [1 round(Int, time()*1.0e6); nx 0]]
append!(S.x[1], rand(nx))

for f in datafields
  v = getfield(S, f)
  @test v[1] != v[2]
end

# Now set all fields like a smart person
S = SeisData(2)
S.id[1] = "...YYY"
S.name[1] = "New Station"
S.loc[1] = zeros(Float64,5)
S.fs[1] = 100.0
S.gain[1] = 2.0
S.resp[1] = [0.0+0.0*im 1.0+1.0*im; 0.0+0.0*im 1.0-1.0*im]
S.units[1] = "Unknown"
S.src[1] = "www"
S.notes[1] = ["sadfasgasfg","kn4ntl42ntlk4n"]
S.misc[1] = Dict{String,Any}("P" => 2.0)
S.t[1] = [1 round(Int, time()*1.0e6); nx 0]
S.x[1] = rand(nx)

S.id[2] = "...zzz"
S.name[2] = "Old Station"
S.loc[2] = ones(Float64,5)
S.fs[2] = 50.0
S.gain[2] = 22.0
S.resp[2] = [0.0+0.0*im 1.0+0.767*im; 0.0+0.0*im 1.0-0.767*im]
S.units[2] = "ms/2"
S.src[2] = "file"
S.notes[2] = ["0913840183","klnelgng"]
S.misc[2] = Dict{String,Any}("S" => 6.5)
S.t[2] = [1 round(Int, time()*1.0e6); nx 0]
S.x[2] = rand(nx)

for i in datafields
  v = getfield(S,i)
  if !isimmutable(v[1])
    @test pointer_from_objref(v[1]) != pointer_from_objref(v[2])
  end
end

# Unambiguous numbered initialization
S1 = SeisData(SeisChannel(), SeisChannel())
S2 = SeisData(2)
S3 = SeisData(S2)
S4 = SeisData(SeisData(1), SeisChannel())
S5 = SeisData(SeisChannel(), SeisData(1))

@test (S1 == S2 == S3 == S4 == S5)
