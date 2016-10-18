using SeisIO

# US SeedLink server
sta = ["GPW UW"; "MBW UW"]
seis = SeedLink(sta, t=60.0)

# US FDSN server
STA = "HOOD,PALM,TIMB,HIYU,TDH"
CHA = "*"
NET = "CC,UW"
T = 600
S = "2016-05-16T14:50:00"
seis = FDSNget(net=NET, sta=STA, cha=CHA, s=S, t=T, v=true)

# Iris web service, single station
seis = irisws(net="CC", sta="TIMB", cha="EHZ", t=300, fmt="miniseed")
writesac(seis)

# Iris web service, multiple stations
STA = ["UW.HOOD.BHZ"; "UW.HOOD.BHN"; "UW.HOOD.BHE"; "CC.TIMB.EHZ"; "CC.TIMB.EHN"; "CC.TIMB.EHE"];
TS = "2016-05-16T14:50:00"; TE = 600;
seis = IRISget(STA, s=TS, t=TE, sync=true);
writesac(seis)

# Download some data from the Tohoku-Oki great earthquake
S = getevt("201103110547", "PB B004  EH?,PB B004  BS?,PB B001  BS?")
