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
    for i = 1:10
      chanspec()
      seed_support()
      mseed_support()
      timespec()
    end
  end
end
