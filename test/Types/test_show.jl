printstyled(stdout,"  show\n", color=:light_green)

# SeisChannel show
S = SeisData()
C = randSeisChannel()
C.fs = 100.0
nx = (1, 2, 3, 4, 5, 10, 100, 10000)
C.t = Array{Int64,2}(undef, 0, 2)
C.x = Float32[]
push!(S, C)
redirect_stdout(out) do
  for i in nx
    C.t = [1 0; i 0]
    C.x = randn(Float32, i)
    show(C)
    push!(S, C)
  end
  show(S)
end

redirect_stdout(out) do
  # show
  show(breaking_seis())
  show(randSeisData(1))
  show(SeisChannel())
  show(SeisData())
  show(randSeisChannel())
  show(randSeisData(10, c=1.0))

  # summary
  summary(randSeisChannel())
  summary(randSeisData())

  # invoke help-only functions
  seed_support()
  mseed_support()
  dataless_support()
  resp_wont_read()
  @test web_chanspec() == nothing
end
