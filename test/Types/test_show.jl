printstyled(stdout,"  show\n", color=:light_green)
S = breaking_seis()
T = randSeisData(1)

open("runtests.log", "a") do out
  redirect_stdout(out) do
    show(SeisChannel())
    show(SeisData())
    show(SeisHdr())
    show(SeisEvent())


    show(randSeisChannel())
    show(S)
    show(T)
    show(randSeisHdr())
    show(randSeisEvent())

    summary(randSeisChannel())
    summary(randSeisData())
    summary(randSeisEvent())
    summary(randSeisHdr())
    
    # invoke help-only functions
    @test seed_support() == nothing
    @test chanspec() == nothing
    @test mseed_support() == nothing
    @test timespec() == nothing
  end
end
