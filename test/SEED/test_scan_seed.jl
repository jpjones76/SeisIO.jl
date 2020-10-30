printstyled("  scan_seed\n", color=:light_green)

fname = string(path, "/SampleFiles/SEED/test.mseed")
test_sac_file = string(path, "/SampleFiles/SAC/test_le.sac")
@test_throws ErrorException scan_seed(test_sac_file)

redirect_stdout(out) do
  soh = scan_seed(fname, v=3)
  S = read_data("mseed", fname)
  h = String.(strip.(split(soh[1], ",")))

  nx = parse(Int64, split(h[2], "=")[2])
  @test nx == length(S.x[1])

  ng = parse(Int64, split(h[3], "=")[2])
  @test ng == 0

  nfs = parse(Int64, split(h[4], "=")[2])
  @test nfs == 1
end

if has_restricted
  redirect_stdout(out) do
    fname = path * "/SampleFiles/Restricted/Steim2-AllDifferences-BE.mseed"
    soh = scan_seed(fname, quiet=true)
    h = String.(strip.(split(soh[1], ",")))

    nx = parse(Int64, split(h[2], "=")[2])
    @test nx == 3096

    ng = parse(Int64, split(h[3], "=")[2])
    @test ng == 0

    nfs = parse(Int64, split(h[4], "=")[2])
    @test nfs == 1

    fname = path * "/SampleFiles/Restricted/SHW.UW.mseed"
    scan_seed(fname, fs_times=true)
    scan_seed(fname, seg_times=true)
    soh = scan_seed(fname, quiet=true)
    S = read_data("mseed", fname)
    nfs_expect = [143, 7]

    for i in 1:S.n
      h = String.(strip.(split(soh[i], ",")))
      nx = parse(Int64, split(h[2], "=")[2])
      @test nx == length(S.x[i])

      # This is occasionally off-by-one from the true total
      ng = parse(Int64, split(h[3], "=")[2])
      @test abs(ng - (size(S.t[i], 1) - 2)) ≤ 1

      nfs = parse(Int64, split(h[4], "=")[2])
      @test nfs == nfs_expect[i]
    end
  end
end
