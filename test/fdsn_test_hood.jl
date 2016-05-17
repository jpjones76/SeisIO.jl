using SeisIO

# US Test
STA = "HOOD,PALM,TIMB,HIYU,TDH"
CHA = "*"
NET = "CC,UW"
T = 600
S = "2016-05-16T14:50:00"

seis = FDSNget(net=NET, sta=STA, cha=CHA, s=S, t=T, v=true)
