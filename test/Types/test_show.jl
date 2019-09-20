printstyled(stdout,"  show\n", color=:light_green)

# SeisChannel show
S = SeisChannel()
nx = (1, 2, 3, 4, 5, 10, 100, 10000)
redirect_stdout(out) do
  for i in nx
    S.t = [1 0; i 0]
    S.x = randn(i)
    show(S)
  end
end

redirect_stdout(out) do
  # show
  show(breaking_seis())
  show(randSeisData(1))
  show(SeisChannel())
  show(SeisData())
  show(randSeisChannel())

  # summary
  summary(randSeisChannel())
  summary(randSeisData())

  # invoke help-only functions
  @test seed_support() == nothing
  @test chanspec() == nothing
  @test mseed_support() == nothing
  @test timespec() == nothing
  @test RESP_wont_read() == nothing
end
