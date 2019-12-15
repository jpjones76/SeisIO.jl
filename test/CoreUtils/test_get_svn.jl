right_url = "https://github.com/jpjones76/SeisIO-TestData/trunk/SVN_test"
wrong_url = "https://github.com/jpjones76/SeisIO-TestData/trunk/DOESNT_EXIST"
svn_dir = "SVN_test"
svn_file = joinpath(svn_dir, "test")

try
  get_svn(right_url, svn_dir)
  @test isfile(svn_file)
  str = readline(svn_file)
  @test str == "."
  rm(svn_file)
  rm(svn_dir)
  @test_throws ErrorException get_svn(wrong_url, "SVN_test")
catch err
  @warn(err)
end
