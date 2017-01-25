using SeisIO

# US FDSNget example: 5 stations, 2 networks, all channels, last 600 seconds
STA = "HOOD,PALM,TIMB,HIYU,TDH"
CHA = "*"
NET = "CC,UW"
TT = -600
TS = u2d(time())
seis = FDSNget(net=NET, sta=STA, cha=CHA, s=TS, t=TT)

# Iris web service, single station, written to miniseed
seis = irisws(net="CC", sta="TIMB", cha="EHZ", t=-300, fmt="miniseed")
writesac(seis)

# IRISget example: 6 channels, 10 minutes, synchronized, saved in SeisIO format"
STA = ["UW.HOOD.BHZ"; "UW.HOOD.BHN"; "UW.HOOD.BHE"; "CC.TIMB.EHZ"; "CC.TIMB.EHN"; "CC.TIMB.EHE"]
S = Dates.DateTime(Dates.year(now()))
T = 600
seis = IRISget(STA, s=S, t=T, y=true)
wseis(seis, "20160516145000.data.seis")

# The Tohoku-Oki great earthquake, from IRIS FDSN, recorded by boreholes in WA (USA)
S = FDSN_evt("201103110547", "PB B004  EH?,PB B004  BS?,PB B001  BS?,PB B001  EH?")
wseis("201103110547.evt.seis", S)

# IRIS SeedLink session in TIME mode
sta = ["GPW UW"; "MBW UW"; "SHUK UW"]
S1 = SeedLink(sta, mode="TIME", s=0, t=120)

# IRIS SeedLink session in DATA mode
S = SeisData()
SeedLink!(S, "SampleFiles/SL_long_test.conf", mode="DATA")
println(STDOUT, "When finished, close connection with command \"close(S.c[1])\"")
