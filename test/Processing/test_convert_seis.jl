printstyled("  seismogram differentiation/integration\n", color=:light_green)

convert_file = path*"/SampleFiles/2019_M7.1_Ridgecrest.seis"
S = randSeisData(3, s=1.0)
S.units = ["m/s2", "m", "m/s"]
U = deepcopy(S)
S1 = deepcopy(S)

printstyled("  conversion to m/s\n", color=:light_green)
redirect_stdout(out) do
  convert_seis!(S, v=3)
  @test S.units[1] == S.units[2] == S.units[3] == "m/s"
  @test S.x[3] == U.x[3]
end

printstyled("  conversion to m/s2\n", color=:light_green)
redirect_stdout(out) do
  convert_seis!(S, v=2, units_out="m/s2")
  @test S.units[1] == S.units[2] == S.units[3] == "m/s2"
  @test isapprox(S.x[1], U.x[1])
end

printstyled("  conversion to m\n", color=:light_green)
redirect_stdout(out) do
  convert_seis!(S1, v=2, units_out="m")
  @test S1.units[1] == S1.units[2] == S1.units[3] == "m"
  @test isapprox(S1.x[2], U.x[2])
end

printstyled("  conversion from m to m/s2 and back to m\n", color=:light_green)
redirect_stdout(out) do
  for j = 1:100
    S = randSeisData(3, s=1.0)
    S.units = ["m", "m", "m"]

    for i = 1:3
      Nx = min(length(S.x[i]), 20000)
      S.t[i] = [1 S.t[i][1,2]; Nx 0]
      S.x[i] = rand(Float64, Nx)
    end
    U = deepcopy(S)

    convert_seis!(S, units_out="m/s2")
    @test S.units[1] == S.units[2] == S.units[3] == "m/s2"
    convert_seis!(S, units_out="m")
    @test S.units[1] == S.units[2] == S.units[3] == "m"

    for i = 1:3
      @test isapprox(S.x[i], U.x[i])
    end
  end
end

printstyled("    at Float32 precision\n", color=:light_green)
redirect_stdout(out) do
  S = rseis(convert_file)[1]
  U = deepcopy(S)
  convert_seis!(S, units_out="m/s2", v=2)
  convert_seis!(S)
  for i = 1:16
    @test isapprox(S.x[i], U.x[i])
  end
end


printstyled("    at Float64 precision\n", color=:light_green)
redirect_stdout(out) do
  S = rseis(convert_file)[1]
  for i = 1:S.n
    S.x[i] = Float64.(S.x[i])
  end
  detrend!(S)

  U = deepcopy(S)
  convert_seis!(S, units_out="m/s2")
  for i = 17:19
     @test S.x[i] == U.x[i]
  end
  convert_seis!(S)
  for i = 1:16
    @test isapprox(S.x[i], U.x[i])
    @test isapprox(S.t[i], U.t[i])
  end

  convert_seis!(S, units_out="m")
  convert_seis!(S, units_out="m/s")
  convert_seis!(S, units_out="m")
  convert_seis!(S, units_out="m/s2")
  T = convert_seis(S, units_out="m")

  # Test on a SeisChannel
  C = deepcopy(U[1])
  convert_seis!(C, units_out="m")
  convert_seis!(C, units_out="m/s")
  convert_seis!(C, units_out="m/s2")
  convert_seis!(C, units_out="m")
  D = convert_seis(C, units_out="m/s2")
end
