import SeisIO:sep, safe_isfile, safe_isdir

change_sep(S::Array{String,1}) = [replace(i, "/" => sep) for i in S]
cfile = path*"/SampleFiles/Restricted/03_02_27_20140927.euc.ch"

printstyled("  safe_isfile\n", color=:light_green)
@test SeisIO.safe_isfile("runtests.jl") == true
@test SeisIO.safe_isfile("foo.jl") == false

printstyled("  safe_isdir\n", color=:light_green)
@test SeisIO.safe_isdir("SampleFiles") == true
@test SeisIO.safe_isdir("Roms") == false


printstyled("  ls\n", color=:light_green)
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
  expected = [joinpath(path, splitdir(S[n])[1], i) for i in S_expect[n]]
  @test change_sep(ls(v)) == change_sep(expected)
  [@test isfile(i) for i in ls(v)]
end
# Test that ls invokes find_regex under the right circumstances
@test change_sep(ls(S[5])) == change_sep(regex_find("SampleFiles/", r"990[1-2].*$"))

if safe_isfile(cfile)
  T = path .* [
                "/SampleFiles/Restricted/*.cnt",
                "/SampleFiles/*",
                "/SampleFiles/Restricted/2014092709*cnt"
              ]
  T_expect =  [63, 92, 60]

  # Test that ls finds the same number of files as `ls -1`
  for (n,v) in enumerate(T)
    s = ls(v)
    @test (isempty(s) == false)
    @test (length(s) == T_expect[n])
    [@test isfile(i) for i in s]
  end

  # Test that ls invokes find_regex under the right circumstances
  @test change_sep(ls(T[2])) == change_sep(regex_find("SampleFiles", r".*$"))
  @test change_sep(ls(T[3])) == change_sep(regex_find("SampleFiles", r"Restricted/2014092709.*cnt$"))
else
  printstyled("  extended ls tests skipped. (files not found; is this Appveyor?)\n", color=:green)
end
