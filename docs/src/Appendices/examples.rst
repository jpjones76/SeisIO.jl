.. _webex:

###############################
Appendix E: Web Client Examples
###############################

***********
FDSN
***********
1. Download 10 minutes of data from four stations at Mt. St. Helens (WA, USA), delete the low-gain channels, and save as SAC files in the current directory.
::

  S = FDSNget("CC.VALT, UW.SEP, UW.SHW, UW.HSR", t=-600)
  S -= "SHW.ELZ..UW"
  S -= "HSR.ELZ..UW"
  writesac(S)

2. Get seismic and strainmeter records for the P-wave of the Tohoku-Oki great earthquake on two borehole stations and write to native SeisData format.
::

  S = FDSNevt("201103110547", "PB.B004..EH?,PB.B004..BS?,PB.B001..BS?,PB.B001..EH?")
  wseis("201103110547_evt.seis", S)


3. 5 stations, 2 networks, all channels, data from the last 600 seconds
::

  CHA = ["CC.PALM, UW.HOOD, UW.TIMB, CC.HIYU, UW.TDH"]
  TS = u2d(time())
  TT = -600
  S = FDSNget(CHA, s=TS, t=TT)

4. An FDSN station query
::

  S = FDSNsta("CC.VALT..,PB.B001..BS?,PB.B001..E??")

5. A request to FDSN Potsdam, not synchronized, with some verbosity

::

  ts = "2011-03-11T06:00:00"
  te = "2011-03-11T06:05:00"
  R = FDSNget("GE.BKB..BH?", src="GFZ", s=ts, t=te, v=1, y=false)

***********
IRISws
***********
1. Get synchronized trace data from IRISws from ``TS`` to ``TE`` at channels ``C``

::

  S = IRISget(C, s=TS, t=TE)

2. Get desynchronized trace data from IRISws with a 5-second timeout on HTTP requests, written directly to disk.
::

  S = IRISget(C, s=TS, t=TE, y=false, vto=5, w=true)

3. Request 10 minutes of continuous vertical-component data from a small May 2016 earthquake swarm at Mt. Hood, OR, USA:
::

  STA = "UW.HOOD.--.BHZ,CC.TIMB.--.EHZ"
  TS = "2016-05-16T14:50:00"; TE = 600
  S = IRISget(STA, s=TS, t=TE)

4. Iris web service, single station, written to miniseed
::

  seis = irisws("CC.TIMB..EHZ", t=-300, fmt="miniseed")
  writesac(seis)

5. IRISget example: 6 channels, 10 minutes, synchronized, saved in SeisIO format"
::

  STA = "UW.HOOD..BH?, CC.TIMB..EH?"
  S = Dates.DateTime(Dates.year(now()))
  T = 600
  seis = IRISget(STA, s=S, t=T, y=true)
  wseis(seis, "20160516145000.data.seis")

6. Grabbing data from a predetermined time window in two different formats
::

  ts = "2016-03-23T23:10:00"
  te = "2016-03-23T23:17:00"
  S = irisws("CC.JRO..BHZ", s=ts, t=te, fmt="sacbl")
  T = irisws("CC.JRO..BHZ", s=ts, t=te, fmt="miniseed")

***********
SeedLink
***********
1. An attended SeedLink session in DATA mode. Initiate a SeedLink session in DATA mode using config file SL.conf and write all packets received directly to file (in addition to parsing to S itself). Set nominal refresh interval for checking for new data to 10 s. A mini-seed file will be generated automatically.

::

  S = SeisData()
  SeedLink!(S, "SL.conf", mode="DATA", r=10, w=true)

2. An unattended SeedLink download in TIME mode. Get the next two minutes of data from stations GPW, MBW, SHUK in the UW network. Put the Julia REPL to sleep while the request fills. If the connection is still open, close it (SeedLink's time bounds arent precise in TIME mode, so this may or may not be necessary). Pause briefly so that the last data packets are written. Synchronize results and write data in native SeisIO file format.

::

  sta = "UW.GPW,UW.MBW,UW.SHUK"
  s0 = now()
  S = SeedLink(sta, mode="TIME", s=s0, t=120, r=10)
  sleep(180)
  isopen(S.c[1]) && close(S.c[1])
  sleep(20)
  sync!(S)
  fname = string("GPW_MBW_SHUK", s0, ".seis")
  wseis(fname, S)

3. A SeedLink session in TIME mode

::

  sta = "UW.GPW, UW.MBW, UW.SHUK"
  S1 = SeedLink(sta, mode="TIME", s=0, t=120)

4. A SeedLink session in DATA mode with multiple servers, including a config file. Data are parsed roughly every 10 seconds. A total of 5 minutes of data are requested.

::

  sta = ["CC.SEP", "UW.HDW"]
  # To ensure precise timing, we'll pass d0 and d1 as strings
  st = 0.0
  en = 300.0
  dt = en-st
  (d0,d1) = parsetimewin(st,en)

  S = SeisData()
  SeedLink!(S, sta, mode="TIME", r=10.0, s=d0, t=d1)
  println(STDOUT, "...first link initialized...")

  # Seedlink with a config file
  config_file = "seedlink.conf"
  SeedLink!(S, config_file, r=10.0, mode="TIME", s=d0, t=d1)
  println(STDOUT, "...second link initialized...")

  # Seedlink with a config string
  SeedLink!(S, "CC.VALT..???, UW.ELK..EHZ", mode="TIME", r=10.0, s=d0, t=d1)
  println(STDOUT, "...third link initialized...")
