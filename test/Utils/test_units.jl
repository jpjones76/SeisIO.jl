printstyled("  units\n", color=:light_green)

# Cases from randSeisChannel
printstyled("    check that RandSeis uses valid UCUM units\n", color=:light_green)
for u in SeisIO.RandSeis.irregular_units
  @test(vucum(u))
  @test units2ucum(u) == u
end
S = randSeisData()
isv = validate_units(S)
@test isv == trues(S.n)

C = S[1]
@test validate_units(C)
@test_logs (:warn, "Error thrown for unit string: meters per second") SeisIO.vucum("meters per second")
@test vucum("m/s^2") == false

# Now some real units that show up constantly in web requests
printstyled("    test conversions to UCUM units\n", color=:light_green)

@test units2ucum("m/s^1")     == "m/s"
@test units2ucum("m/s**1")    == "m/s"
@test units2ucum("m s^-1")    == "m/s"
@test units2ucum("m*s^-1")    == "m/s"
@test units2ucum("m.s^-1")    == "m/s"
@test units2ucum("m⋅s^-1")    == "m/s"
@test units2ucum("m s**-1")   == "m/s"
@test units2ucum("m*s**-1")   == "m/s"
@test units2ucum("m.s**-1")   == "m/s"
@test units2ucum("m⋅s**-1")   == "m/s"
@test units2ucum("m × s^-1")  == "m/s"
@test units2ucum("m ⋅ s^-1")  == "m/s"

@test units2ucum("nm/s")      == "nm/s"
@test units2ucum("nm/s^1")    == "nm/s"
@test units2ucum("nm/s**1")   == "nm/s"
@test units2ucum("nm s^-1")   == "nm/s"
@test units2ucum("nm*s^-1")   == "nm/s"
@test units2ucum("nm.s^-1")   == "nm/s"
@test units2ucum("nm.s**-1")  == "nm/s"
@test units2ucum("nm*s**-1")  == "nm/s"
@test units2ucum("nm s**-1")  == "nm/s"

# Acceleration
@test units2ucum("m/s^2")   == "m/s2"
@test units2ucum("m/s**2")  == "m/s2"
@test units2ucum("m s^-2")  == "m/s2"
@test units2ucum("m*s^-2")  == "m/s2"
@test units2ucum("m.s^-2")  == "m/s2"
@test units2ucum("m⋅s^-2")  == "m/s2"
@test units2ucum("m s**-2") == "m/s2"
@test units2ucum("m*s**-2") == "m/s2"
@test units2ucum("m.s**-2") == "m/s2"
@test units2ucum("m⋅s**-2") == "m/s2"

# Fictitious cases; we're unlikely to see anything like these
@test units2ucum("s^43/s**3") == "s43/s3"
@test units2ucum("s**10/m^4") == "s10/m4"
@test units2ucum("s^43 m**-3") == "s43/m3"
@test units2ucum("s^43 cm^-3") == "s43/cm3"
@test units2ucum("s^43 cm^-3 g") == "s43/cm3.g"
@test units2ucum("s^43 cm**+3 g") == "s43.cm3.g"
@test units2ucum("m s^-1 K") == "m/s.K"
@test units2ucum("m s^-1*K") == "m/s.K"
@test units2ucum("s^43 cm^-3 V^-4") == "s43/cm3.V4"
@test units2ucum("s^43.cm^-3*V^-4") == "s43/cm3.V4"
