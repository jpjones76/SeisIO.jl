import SeisIO:sep, safe_isfile, safe_isdir

printstyled("  safe_isfile\n", color=:light_green)
@test safe_isfile("runtests.jl") == true
@test safe_isfile("foo.jl") == false

printstyled("  safe_isdir\n", color=:light_green)
@test safe_isdir("SampleFiles") == true
@test safe_isdir("Roms") == false

printstyled("  ls\n", color=:light_green)

cfile = path*"/SampleFiles/Restricted/03_02_27_20140927.euc.ch"
@test any([occursin("test", i) for i in ls()])

S = [
      "CoreUtils/",
      "CoreUtils/test_ls.jl",
      "CoreUtils/poo",
      "SampleFiles/99*",
      "SampleFiles/990[1-2]*",
      "CoreUtils/test_*"
    ]
S_expect =  [
              ["test_ls.jl", "test_time.jl"],
              ["test_ls.jl"],
              String[],
              ["99011116541W", "99011116541o"],
              ["99011116541W", "99011116541o"],
              ["test_ls.jl", "test_time.jl"]
            ]

# Test that ls returns the same files as `ls -1`
for (n,v) in enumerate(S)
  files = String[splitdir(i)[2] for i in ls(v)]
  deleteat!(files, findall([endswith(i, "cov") for i in files]))
  expected = S_expect[n]
  @test files == expected
  [@test isfile(f) for f in ls(v)]
end
# Test that ls invokes find_regex under the right circumstances
@test change_sep(ls(S[5])) == change_sep(regex_find("SampleFiles/", r"990[1-2].*$"))

if safe_isfile(cfile)
  T = path .* [
                "/SampleFiles/Restricted/*.cnt",
                "/SampleFiles/*",
                "/SampleFiles/Restricted/2014092709*cnt"
              ]
  T_expect =  [63, 129, 60]

  # Test that ls finds the same number of files as `ls -1`
  for (n,v) in enumerate(T)
    files = ls(v)
    @test (isempty(files) == false)
    @test (length(files) == T_expect[n])
    [@test isfile(f) for f in files]
  end

  # Test that ls invokes find_regex under the right circumstances
  @test change_sep(ls(T[2])) == change_sep(regex_find("SampleFiles", r".*$"))
  @test change_sep(ls(T[3])) == change_sep(regex_find("SampleFiles", r"Restricted/2014092709.*cnt$"))
else
  printstyled("  extended ls tests skipped. (files not found; is this Appveyor?)\n", color=:green)
end

if Sys.iswindows()
  @test safe_isfile("http://google.com") == false
  @test safe_isdir("http://google.com") == false
end
