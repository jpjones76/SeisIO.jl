SUDS_fmt = FormatDesc(
  "SUDS (Seismic Universal Data System)",
  "\"suds\"",
  "U.S. Geological Survey and University of Alaska, Fairbanks, Alaska, USA",
  "http://www.iris.edu/pub/programs/sel/sun/SUDS.2.6_tar.Z",
  "Banfill Software Engineering <info@banfill.net>",
  HistVec(),
  ["uses SEED-like data structures, some of which are followed by data",
  "each packet has a structure identifier, a structure, and possibly data",
  "documentation contains many inconsistences and errors",
  "WIN-SUDS won't run on 64-bit systems, even in legacy mode",
  "PC-SUDS software requires a DOS emulator",
  "developed by Peter Ward, USGS, Menlo Park, CA, USA"
  ],
  ["US Geological Survey (USGS)",
  "USGS Volcano Disaster Assistance Program (VDAP)",
  "Alaska Volcano Observatory (AVO)",
  "Observatorio Vulcanológico y Sismológico de Costa Rica (OVISCORI)",
  "volcano monitoring"],
  ["https://pubs.usgs.gov/of/1989/0188/report.pdf",
  "https://banfill.net/suds/PC-SUDS.pdf",
  "https://banfill.net/suds/Win-SUDS.pdf",
  "docs/Formats/suds_man.pdf"],
  0xff
  )
SUDS_fmt.ver = [  FmtVer(2.6, "1994-05-11", false) ,
                FmtVer(1.41, "1989-03-29", nothing)
                ]
formats["SUDS"] = SUDS_fmt
