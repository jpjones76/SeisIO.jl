using SeisIO

# US SeedLink server
sta = ["GPW UW"; "MBW UW"; "SHUK UW"]
seis = SeedLink(sta, t=60, v=true)

# US FDSN server, multiple stations
STA = "HOOD,PALM,TIMB,HIYU,TDH"
CHA = "*"
NET = "CC,UW"
T = -600
S = now()
seis = FDSNget(net=NET, sta=STA, cha=CHA, s=S, t=T, v=true)

# Iris web service, single station, written to SAC
seis = irisws(net="CC", sta="TIMB", cha="EHZ", t=300, fmt="miniseed")
writesac(seis)

# Iris web service, multiple stations, saved to SeisIO native
STA = ["UW.HOOD.BHZ"; "UW.HOOD.BHN"; "UW.HOOD.BHE"; "CC.TIMB.EHZ"; "CC.TIMB.EHN"; "CC.TIMB.EHE"]
S = "2016-05-16T14:50:00"
T = 600
seis = IRISget(STA, s=S, t=T, sync=true)
wseis(seis, "test.seis")

# The Tohoku-Oki great earthquake, from IRIS FDSN, recorded by boreholes in WA (USA)
S = getevt("201103110547", "PB B004  EH?,PB B004  BS?,PB B001  BS?")
wseis("test.seis", S)
