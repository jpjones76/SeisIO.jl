.. _webex:

########
Examples
########

***********************
Timeseries data queries
***********************

FDSN dataselect
===============

1. Download 10 minutes of data from four stations at Mt. St. Helens (WA, USA), delete the low-gain channels, and save as SAC files in the current directory.
::

  S = get_data("FDSN", "CC.VALT, UW.SEP, UW.SHW, UW.HSR", src="IRIS", t=-600)
  S -= "SHW.ELZ..UW"
  S -= "HSR.ELZ..UW"
  writesac(S)

2. Get 5 stations, 2 networks, all channels, last 600 seconds of data at IRIS
::

  CHA = "CC.PALM, UW.HOOD, UW.TIMB, CC.HIYU, UW.TDH"
  TS = u2d(time())
  TT = -600
  S = get_data("FDSN", CHA, src="IRIS", s=TS, t=TT)

3. A request to FDSN Potsdam, time-synchronized, with some verbosity
::

  ts = "2011-03-11T06:00:00"
  te = "2011-03-11T06:05:00"
  R = get_data("FDSN", "GE.BKB..BH?", src="GFZ", s=ts, t=te, v=1, y=true)

IRIS timeseries
===============

Note that the "src" keyword is not used in IRIS queries.

1. Get trace data from IRISws from ``TS`` to ``TT`` at channels ``CHA``

::

  S = SeisData()
  CHA = "UW.TDH..EHZ, UW.VLL..EHZ, CC.VALT..BHZ"
  TS = u2d(time()-86400)
  TT = 600
  get_data!(S, "IRIS", CHA, s=TS, t=TT)

2. Get synchronized trace data from IRISws with a 55-second timeout on HTTP requests, written directly to disk.
::

  CHA = "UW.TDH..EHZ, UW.VLL..EHZ, CC.VALT..BHZ"
  TS = u2d(time())
  TT = -600
  S = get_data("IRIS", CHA, s=TS, t=TT, y=true, to=55, w=true)

3. Request 10 minutes of continuous vertical-component data from a small May 2016 earthquake swarm at Mt. Hood, OR, USA:
::

  STA = "UW.HOOD.--.BHZ,CC.TIMB.--.EHZ"
  TS = "2016-05-16T14:50:00"; TE = 600
  S = get_data("IRIS", STA, "", s=TS, t=TE)

4. Grab data from a predetermined time window in two different formats
::

  ts = "2016-03-23T23:10:00"
  te = "2016-03-23T23:17:00"
  S = get_data("IRIS", "CC.JRO..BHZ", s=ts, t=te, fmt="sacbl")
  T = get_data("IRIS", "CC.JRO..BHZ", s=ts, t=te, fmt="miniseed")

******************
FDSN station query
******************

Get channel information for strain and seismic channels at station PB.B001:

::

  S = FDSNsta("CC.VALT..,PB.B001..BS?,PB.B001..E??")

****************
FDSN event query
****************

Get seismic and strainmeter records for the P-wave of the Tohoku-Oki great earthquake on two borehole stations and write to native SeisData format:
::

  S = FDSNevt("201103110547", "PB.B004..EH?,PB.B004..BS?,PB.B001..BS?,PB.B001..EH?")
  wseis("201103110547_evt.seis", S)


*****************
SeedLink sessions
*****************
1. An attended SeedLink session in DATA mode. Initiate a SeedLink session in DATA mode using config file SL.conf and write all packets received directly to file (in addition to parsing to S itself). Set nominal refresh interval for checking for new data to 10 s. A mini-seed file will be generated automatically.
::

  S = SeisData()
  seedlink!(S, "SL.conf", mode="DATA", r=10, w=true)

2. An unattended SeedLink download in TIME mode. Get the next two minutes of data from stations GPW, MBW, SHUK in the UW network. Put the Julia REPL to sleep while the request fills. If the connection is still open, close it (SeedLink's time bounds arent precise in TIME mode, so this may or may not be necessary). Pause briefly so that the last data packets are written. Synchronize results and write data in native SeisIO file format.
::

  sta = "UW.GPW,UW.MBW,UW.SHUK"
  s0 = now()
  S = seedlink(sta, mode="TIME", s=s0, t=120, r=10)
  sleep(180)
  isopen(S.c[1]) && close(S.c[1])
  sleep(20)
  sync!(S)
  fname = string("GPW_MBW_SHUK", s0, ".seis")
  wseis(fname, S)

3. A SeedLink session in TIME mode
::

  sta = "UW.GPW, UW.MBW, UW.SHUK"
  S1 = seedlink(sta, mode="TIME", s=0, t=120)

4. A SeedLink session in DATA mode with multiple servers, including a config file. Data are parsed roughly every 10 seconds. A total of 5 minutes of data are requested.
::

  sta = ["CC.SEP", "UW.HDW"]
  # To ensure precise timing, we'll pass d0 and d1 as strings
  st = 0.0
  en = 300.0
  dt = en-st
  (d0,d1) = parsetimewin(st,en)

  S = SeisData()
  seedlink!(S, sta, mode="TIME", r=10.0, s=d0, t=d1)
  println(stdout, "...first link initialized...")

  # Seedlink with a config file
  config_file = "seedlink.conf"
  seedlink!(S, config_file, r=10.0, mode="TIME", s=d0, t=d1)
  println(stdout, "...second link initialized...")

  # Seedlink with a config string
  seedlink!(S, "CC.VALT..???, UW.ELK..EHZ", mode="TIME", r=10.0, s=d0, t=d1)
  println(stdout, "...third link initialized...")
