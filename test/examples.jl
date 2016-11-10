using SeisIO

# IRIS SeedLink server
println("SeedLink example: TIME mode, 3 stations, IRIS server")
sta = ["GPW UW"; "MBW UW"; "SHUK UW"]
seis = SeedLink(sta, s=now(), t=60)

# US FDSN get, multiple stations
println("FDSNget example: 5 stations, 2 networks, all channels, 600 seconds")
STA = "HOOD,PALM,TIMB,HIYU,TDH"
CHA = "*"
NET = "CC,UW"
T = -600
S = now()
seis = FDSNget(net=NET, sta=STA, cha=CHA, s=S, t=T)

# Iris web service, single station, written to SAC
println("irisws example saved as mini-SEED")
seis = irisws(net="CC", sta="TIMB", cha="EHZ", t=300, fmt="miniseed")
writesac(seis)

# Iris web service, multiple stations, saved to SeisIO native
println("IRISget example: 6 channels, 10 minutes, synchronized, saved in SeisIO format")
STA = ["UW.HOOD.BHZ"; "UW.HOOD.BHN"; "UW.HOOD.BHE"; "CC.TIMB.EHZ"; "CC.TIMB.EHN"; "CC.TIMB.EHE"]
S = "2016-05-16T14:50:00"
T = 600
seis = IRISget(STA, s=S, t=T, sync=true)
wseis(seis, "20160516145000.data.seis")

# The Tohoku-Oki great earthquake, from IRIS FDSN, recorded by boreholes in WA (USA)
println("getevt example: Tohoku-Oki (Mw 9.0), seismic + strain data, saved in SeisIO format")
S = getevt("201103110547", "PB B004  EH?,PB B004  BS?,PB B001  BS?,PB B001  EH?")
wseis("201103110547.evt.seis", S)
