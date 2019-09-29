AH_fmt = FormatDesc(
  "AH (Ad Hoc)",
  "\"ah1\" (AH-1), \"ah2\" (AH-2)",
  "Columbia University, New York, United States of America",
  "ftp://www.orfeus-eu.org/pub/software/mirror/ldeo.columbia/ (defunct)",
  "unknown",
  HistVec(),
  ["machine-independent file format using External Data Representation (XDR)"],
  ["Comprehensive Nuclear Test Ban Tready (CTBT) monitoring",
    "earthquake seismology",
    "Lamont-Doherty Earth Observatory (Columbia University, NY, USA)",
    "Borovoye Geophysical Observatory, Kazakhstan",
    "CORAL by K. Creager (U. Washington, Seattle, WA, USA)"],
  ["none known"],
  0x00
  )
AH_fmt.ver = [ FmtVer(2.0, Date("1994-02-20"), false),
                FmtVer(1.0, Date("1985-06-11"), false)
                ]
formats["ah1"] = AH_fmt
formats["ah2"] = AH_fmt

Bottle_fmt = FormatDesc(
  "Bottle",
  "\"bottle\"",
  "UNAVCO, Boulder, Colorado, United States",
  "(none)",
  "data@unavco.org",
  HistVec(),
  ["a portable, simple data format designed for short sequences of",
  " single-channel time series data"],
  ["geodesy; raw format of PBO strain meter stations"],
  ["https://www.unavco.org/data/strain-seismic/bsm-data/lib/docs/bottle_format.pdf"],
  0x00
  )
Bottle_fmt.ver = [ FmtVer("1", "Unknown", false) ]
formats["bottle"] = Bottle_fmt

DATALESS_fmt = FormatDesc(
  "Dataless SEED (instrument metadata) file",
  "\"dataless\"",
  "International Federation of Digital Seismograph Networks (FDSN)",
  "(none)",
  "webmaster@fdsn.org",
  HistVec(),
  ["contains Volume, Abbreviation, and Station Control Headers.",
  "no Time Span Control Headers or data records.",
  "blockettes are completely non-unique; all info can appear in at least",
  "  four places, because SEED wasn't confusing and bloated enough.",
  "documentation is terrible as usual, many critical caveats in notes",
  "  or margins (or simply not present).",
  "the SEED manual makes less sense than bathroom stall graffiti."
  ],
  ["FDSN data standard; used worldwide"],
  ["http://www.fdsn.org/pdf/SEEDManual_V2.4.pdf"],
  0x01
  )
DATALESS_fmt.ver = [ FmtVer("2.4", Date("2012-08-01"), false),
                      FmtVer("2.3", Date("1992-12-31"), false),
                      FmtVer("2.2", Date("1991-08-31"), false),
                      ]
formats["dataless"] = DATALESS_fmt

GeoCSV_fmt = FormatDesc(
  "GeoCSV",
  "\"geocsv\", \"geocsv.slist\"",
  "Incorporated Research Institutions for Seismology (IRIS), Washington, DC, United States of America",
  "(none)",
  "info@iris.edu",
  HistVec(),
  ["ASCII format intended for both human and machine readability.",
   "single-column (geocsv.slist) and two-column (geoscv) formats."],
  [ "(unknown)"],
  ["http://geows.ds.iris.edu/documents/GeoCSV.pdf",
  "https://giswiki.hsr.ch/GeoCSV"],
  0x01
  )
GeoCSV_fmt.ver = [ FmtVer("2.0.4", "2015-07-21", false) ]
formats["geocsv"] = GeoCSV_fmt
formats["geocsv.slist"] = GeoCSV_fmt
formats["geocsv.tspair"] = GeoCSV_fmt

Lennartz_fmt = FormatDesc(
  "Lennartz MarsLite ASCII",
  "\"lenartzascii\"",
  "Lennartz electronic GmbH, Tübingen, Germany",
  "(none)",
  "info@lennartz-electronic.de",
  HistVec(),
  ["SLIST (single-column ASCII) variant recorded by Lennartz MarsLite digitizers."],
  [ "Lennartz"],
  ["(none)"],
  0x01
  )
Lennartz_fmt.ver = [ FmtVer("", "", false) ]
formats["lenartzascii"] = Lennartz_fmt

mSEED_fmt = FormatDesc(
  "SEED (Standard for the Exchange of Earthquake Data)",
  "\"mseed\"",
  "International Federation of Digital Seismograph Networks (FDSN)",
  "(no source code)",
  "webmaster@fdsn.org",
  HistVec(),
  ["an omnibus seismic data standard for data archival and detailed network",
  "  and instrument descriptions",
  "mini-SEED is a data-only variant that uses only data blockettes",
  "documentation (official manual) is poorly organized and incomplete at",
  "  224 pages length, 7 years since last update",
  "intentionally abstruse; this is what happens when coders decide to get",
  "  \"clever\" with no Project Managers or Business Analysts to guide them",
  "a slow, turgid monolith, comically inappropriate for long time series",
  ],
  ["FDSN data standard; used worldwide"],
  ["http://www.fdsn.org/pdf/SEEDManual_V2.4.pdf"],
  0x01
  )
mSEED_fmt.ver = [ FmtVer("2.4", Date("2012-08-01"), false) ]
formats["mseed"] = mSEED_fmt

RESP_fmt = FormatDesc(
  "SEED RESP (instrument response) file",
  "\"resp\"",
  "Incorporated Research Institutions for Seismology (IRIS), Washington, DC, United States of America",
  "(no known source code)",
  "info@iris.edu",
  HistVec(),
  ["ASCII instrument responses in a format compatible with SEED blockettes",
   "extremely self-incompatible and easy to break, even compared to SEED",
   "no low-level ASCII file format description or API is known to exist"
  ],
  ["people who like making extra work for themselves"],
  ["https://ds.iris.edu/ds/nodes/dmc/data/formats/resp/"],
  0x01
  )
formats["resp"] = RESP_fmt

SAC_fmt = FormatDesc(
  "SAC (Seismic Analysis Code)",
  "\"sac\"",
  "Lawrence Livermore National Laboratory (LLNL), Livermore, California, United States of America",
  "https://ds.iris.edu/ds/nodes/dmc/software/downloads/sac/101-6a/",
  "Brian Savage, University of Rhode Island (URI) / Arthur Snoke, Department of Geosciences at Virginia Tech (VT)",
  HistVec(),
  ["machine-independent format for storing geophysical data at 32-bit precision",
  "SAC software has distribution restrictions; see https://www.ecfr.gov/cgi-bin/retrieveECFR?n=15y2.1.3.4.30",
  ],
  [ "US Geological Survey (USGS), United States of America",
    "Incorporated Research Institutions for Seismology (IRIS), Washington, DC, United States of America",
    "widely used in North America, South America, and Japan"
    ],
  ["http://ds.iris.edu/files/sac-manual/manual/file_format.html (complete and verified)" ,
  ],
  0x01
  )
SAC_fmt.ver = [ FmtVer("101.6a", Date("2012-01-01"), true) ]
formats["sac"] = SAC_fmt

SACPZ_fmt = FormatDesc(
  "SACPZ (Seismic Analysis Code Poles and Zeros file)",
  "\"sacpz\"",
  "Lawrence Livermore National Laboratory (LLNL), Livermore, California, United States of America",
  "(no source code)",
  "Brian Savage, University of Rhode Island (URI) / Arthur Snoke, Department of Geosciences at Virginia Tech (VT)",
  HistVec(),
  ["ASCII pole-zero file format intended to describe seismic instrument response",
  ],
  [ "US Geological Survey (USGS), United States of America",
    "Incorporated Research Institutions for Seismology (IRIS), Washington, DC, United States of America",
    "widely used in North America, South America, and Japan"
    ],
  ["https://service.iris.edu/irisws/sacpz/docs/1/help/" ,
  ],
  0x01
  )
SACPZ_fmt.ver = [ FmtVer("101.6a", Date("2012-01-01"), true) ]
formats["sacpz"] = SACPZ_fmt

SEGY_fmt = FormatDesc(
  "SEG Y",
  "\"segy\" (SEG Y 1.0 or SEG Y rev 1), \"passcal\" (PASSCAL SEG Y)",
  "Society of Exploration Geophysicists, Tulsa, Oklahoma, United States",
  "(no source code)",
  "SEG Technical Standards Committee,\nhttps://seg.org/Publications/SEG-Technical-Standards",
  HistVec(),
  ["machine-independent open-standard format for storing geophysical data",
  "in SEG Y 1.0 and SEG Y rev 1, header variables were NOT required",
  "  only \"recommended\"; resultantly some industry files won't read",
  "PASSCAL is a SEG Y variant with no file header, developed by PASSCAL",
  "  and New Mexico Tech (USA), used with their equipment through late 2000s"
  ],
  [ "widely used in exploration geophysics",
    "petroleum and gas industry",
    "Portable Array Seismic Studies of the Continental Lithosphere (PASSCAL) Instrument Center, Socorro, New Mexico, USA",
    "New Mexico Institute of Mining and Technology, Socorro, New Mexico, USA"
    ],
  ["https://en.wikipedia.org/wiki/SEG-Y",
  "https://seg.org/Portals/0/SEG/News%20and%20Resources/Technical%20Standards/seg_y_rev2_0-mar2017.pdf",
  "https://www.passcal.nmt.edu/content/passcal-seg-y-trace-header (PASSCAL SEG Y)"
  ],
  0x01
  )
SEGY_fmt.ver = [ FmtVer("rev 2", Date("2017-03-01"), nothing),
                FmtVer("rev 1", Date("2002-05-01"), false),
                FmtVer("PASSCAL", "199?-??-??", false),
                FmtVer(1.0, Date("1974-04-01"), false),
                ]
formats["segy"] = SEGY_fmt
formats["passcal"] = SEGY_fmt

SLIST_fmt = FormatDesc(
  "SLIST (ASCII sample list)",
  "\"slist\"",
  "unknown",
  "(no source code)",
  "unknown",
  HistVec(),
  ["A one-line ASCII header followed by numbers stored as ASCII strings"],
  ["unknown"],
  ["unknown"],
  0x00
  )
formats["slist"] = SLIST_fmt

SXML_fmt = FormatDesc(
  "FDSN Station XML",
  "\"sxml\"",
  "International Federation of Digital Seismograph Networks (FDSN)",
  "(no source code)",
  "webmaster@fdsn.org",
  HistVec(),
  ["XML representation of important common structures in SEED 2.4 metadata."],
  ["FDSN data standard; used worldwide"],
  ["http://www.fdsn.org/xml/station/",
  "http://www.fdsn.org/xml/station/fdsn-station-1.1.xsd",
  "http://www.fdsn.org/pdf/SEEDManual_V2.4.pdf"],
  0x01
  )
formats["FDSN Station XML"] = SXML_fmt

WIN_fmt = FormatDesc(
  "WIN",
  "\"win32\"",
  "Earthquake Research Institute, University of Tokyo, Japan",
  "http://wwweic.eri.u-tokyo.ac.jp/WIN/pub/win/ (in Japanese)",
  "(unknown)",
  HistVec(),
  ["format for storing multiplexed seismic data in one-minute chunks",
  "each data file divides data into one-second segments by channel",
  "  stored as variable-precision delta-encoded integers",
  "channel information must be retrieved from an external file",
  "channel files are not strictly controlled by a central authority and",
  "  inconsistencies in channel parameters are known to exist."
  ],
  [ "used throughout Japan",
    "Earthquake Research Institute, University of Tokyo, Japan",
    "National Research Institute for Earth Science and Disaster Resilience (NIED), Japan"
    ],
  ["http://wwweic.eri.u-tokyo.ac.jp/WIN/ (in Japanese)",
  "https://hinetwww11.bosai.go.jp/auth/?LANG=en (login required)"],
  0x01
  )
WIN_fmt.ver = [ FmtVer("3.0.2", Date("2017-11-20"), false) ]
formats["Win32"] = WIN_fmt
