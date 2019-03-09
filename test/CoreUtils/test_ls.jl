import SeisIO:sep

change_sep(S::Array{String,1}) = [replace(i, "/" => sep) for i in S]

printstyled("  safe_isfile...\n", color=:light_green)
@test SeisIO.safe_isfile("runtests.jl") == true
@test SeisIO.safe_isfile("foo.jl") == false


printstyled("  ls...\n", color=:light_green)

S = [
      "CoreUtils/",
      "CoreUtils/test_ls.jl",
      "CoreUtils/poo",
      "SampleFiles/Win32/201409271*cnt",
      "SampleFiles/Win32/201409271[0-5]*cnt",
      "CoreUtils/test_*"
    ]
S_expect =  [
              ["test_ls.jl", "test_time.jl"],
              ["test_ls.jl"],
              String[],
              ["2014092712000302.cnt"],
              ["2014092712000302.cnt"],
              ["test_ls.jl", "test_time.jl"]
            ]
T = path .* [
              "/SampleFiles/Win32/*.cnt",
              "/SampleFiles/*",
              "/SampleFiles/Win*/2014092709*cnt"
            ]
T_expect =  [62, 91, 60]


# Test that ls returns the same files as `ls -1`
for (n,v) in enumerate(S)
  expected = [joinpath(path, splitdir(S[n])[1], i) for i in S_expect[n]]
  @test change_sep(ls(v)) == change_sep(expected)
  [@test isfile(i) for i in ls(v)]
end

# Test that ls finds the same number of files as `ls -1`
for (n,v) in enumerate(T)
  s = ls(v)
  @test (isempty(s) == false)
  @test (length(s) == T_expect[n])
  [@test isfile(i) for i in s]
end

# Test that ls invokes find_regex under the right circumstances
@test change_sep(ls(S[5])) == change_sep(regex_find("SampleFiles/Win32", r"201409271[0-5].*cnt$"))
@test change_sep(ls(T[2])) == change_sep(regex_find("SampleFiles", r".*$"))
@test change_sep(ls(T[3])) == change_sep(regex_find("SampleFiles", r"Win.*/2014092709.*cnt$"))
