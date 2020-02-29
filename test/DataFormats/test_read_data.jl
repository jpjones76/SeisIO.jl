nx_add = 1400000
nx_new = 36000
pref = path * "/SampleFiles/"
cfile = pref * "Restricted/03_02_27_20140927.sjis.ch"
files = String[ "UW/00012502123W"               "uw"            "_"
                "SEGY/03.334.12.09.00.0362.1"   "passcal"       "pa-full"
                "SEGY/03.334.12.09.00.0362.1"   "passcal"       "passcal"
                "SAC/test_le.sac"               "sac"           "_"
                "SEED/test.mseed"               "mseed"         "_"
                "Restricted/2014092709*.cnt"    "win32"         "win"
                "ASCII/0215162000.c00"          "lennartz"      "_"
                "ASCII/geo-slist.csv"           "geocsv.slist"  "_"
                "Restricted/SHW.UW.mseed"       "mseed"         "lo-mem"
                "Restricted/test_rev_1.segy"    "segy"          "full"
                "Restricted/test_rev_1.segy"    "segy"          "_"
                "SAC/test_be.sac"               "sac"           "full"
                "SAC/test_be.sac"               "sac"           "_"
                "ASCII/geo-tspair.csv"          "geocsv"        "_"
                ]

# Do not run on Appveyor; it can't access restricted files, so this breaks
printstyled("  read_data\n", color=:light_green)
nf = size(files,1)
for n = 1:nf
  fname = pref * files[n,1]
  if (occursin("Restricted", fname)==false || (has_restricted==true))
    fwild = fname[1:end-1] * "*"
    f_call = files[n,2]
    opt = files[n,3]
    printstyled(string("    ", n, "/", nf, " ", f_call, "\n"), color=:light_green)
    if opt == "pa-full"
      S = verified_read_data("passcal", fname, full=true)
      S = verified_read_data("passcal", fwild, full=true)
      S = read_data("passcal", fwild, full=true, memmap=true)
      S = read_data(fname)
      S = read_data(fname, full=true)
    elseif opt == "win"
      S = verified_read_data(f_call, fwild, cf=cfile)
      S = read_data(f_call, fwild, memmap=true, cf=cfile)
      S = read_data(fwild, cf=cfile)
      S = read_data(f_call, [fwild], cf=cfile)
    elseif opt == "slist"
      S = verified_read_data("geocsv.slist", fname)
      S = verified_read_data("geocsv.slist", fwild)
      S = read_data("geocsv.slist", fwild, memmap=true)
      S = read_data(fwild)
    elseif opt == "lo-mem"
      S = verified_read_data(f_call, fname, nx_new=nx_new, nx_add=nx_add)
      S = verified_read_data(f_call, fwild, nx_new=nx_new, nx_add=nx_add)
      S = read_data(f_call, fwild, nx_new=nx_new, nx_add=nx_add, memmap=true)
    elseif opt == "full"
      S = verified_read_data(f_call, fname, full=true)
      S = verified_read_data(f_call, fwild, full=true)
      S = read_data(f_call, fwild, full=true, memmap=true)
      S = read_data(fwild, full=true)
    else
      S = verified_read_data(f_call, fname)
      S = read_data(f_call, fname, memmap=true)
      if f_call == "uw"
        fwild = fname[1:end-3]*"*"*"W"
      end
      S = read_data(f_call, fwild, memmap=true)
      S = read_data(fwild)
    end
  end
end

# Test for reading a String array of file names
pref = path * "/SampleFiles/"
files = pref .* ["SAC/test_be.sac", "SAC/test_le.sac"]
S = verified_read_data("sac", files, vl=true)
for f in files
  for i in 1:S.n
    @test any([occursin(abspath(f), n) for n in S.notes[i]])
  end
end

# Check that other array methods work
S1 = SeisData()
S2 = SeisData()
read_data!(S1, "sac", files, vl=true)
read_data!(S2, files, vl=true)
S3 = read_data(files, vl=true)
@test S == S1 == S2 == S3

# Does a string array read the same way as a wildcard read?
compare_SeisData(S, verified_read_data("sac", pref .* "SAC/test*sac", vl=true))

# source logging
printstyled("    logging\n", color=:light_green)
uwf1 = joinpath(path, "SampleFiles/UW/99011116541")
uwf4 = joinpath(path, "SampleFiles/UW/00012502123W")
p1 = abspath(uwf1*"W")
p2 = abspath(uwf4)

S = read_data("uw", [uwf1*"W", uwf4])
for i in 1:S.n
  if length(S.t[i]) == 6
    @test S.src[i] == p2
  else
    @test S.src[i] == (S.t[i][1,2] ≥ 946684800000000 ? p2 : p1)
  end
end

@test_throws ErrorException verified_read_data("deez", "nutz.sac")
nothing
