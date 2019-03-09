import SeisIO: safe_isfile
segy_file = string(path, "/SampleFiles/02.050.02.01.34.0572.6")
segy_file_2 = string(path, "SampleFiles/test2.001.segy")

printstyled("  SEG Y...\n", color=:light_green)
printstyled("    PASSCAL/NMT SEG Y...\n", color=:light_green)
SEG = readsegy(segy_file, passcal=true, full=true)

printstyled("    headers...\n", color=:light_green)
@test ≈(1/SEG.gain, 1.9073486328125e-6)
@test ≈(SEG.misc["year"], 2002)
@test ≈(SEG.misc["day"], 50)
@test ≈(SEG.misc["hour"], 2)
@test ≈(SEG.misc["min"], 1)
@test ≈(SEG.misc["sec"], 34)
@test ≈(SEG.fs, 100.0)

printstyled("    data...\n", color=:light_green)
@test ≈(SEG.x[1:10], [-1217,-1248,-1252,-1258,-1251,-1243,-1204,-1178,-1188,-1157])

open("show.log", "w") do out
  redirect_stdout(out) do
    segyhdr(segy_file, passcal=true)
  end
end

if safe_isfile(segy_file_2)
  printstyled("    SEG Y rev 1...\n", color=:light_green)
  SEG = readsegy(segy_file_2)
else
  printstyled("    Skipped SEG Y rev 1...\n", color=:light_green)
end
