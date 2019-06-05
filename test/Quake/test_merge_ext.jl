# Merge with EventTraceData
printstyled(stdout,"      merge! on EventTraceData\n", color=:light_green)

(S,T) = mktestseis()
W = convert(EventTraceData, S)
merge!(W)
V = purge(W)
purge!(W)
@test W == V

printstyled(stdout,"      mseis! with Types from SeisIO.Quake\n", color=:light_green)
S = randSeisData()
mseis!(S, convert(EventChannel, randSeisChannel()),
            convert(EventTraceData, randSeisData()),
            randSeisEvent())
# 
# printstyled(stdout,"    distributivity: S1*S3 + S2*S3 == (S1+S2)*S3\n", color=:light_green)
# imax = 10
# printstyled("      trial ", color=:light_green)
# for i = 1:imax
#   if i > 1
#     print("\b\b\b\b\b")
#   end
#   printstyled(string(lpad(i, 2), "/", imax), color=:light_green)
#   S1 = randSeisData()
#   S2 = randSeisData()
#   S3 = randSeisData()
#   # M1 = (S1+S2)*S3
#   # M2 = S1*S3 + S2*S3
#   @test ((S1+S2)*S3) == (S1*S3 + S2*S3)
#   if i == imax
#     println("")
#   end
# end
