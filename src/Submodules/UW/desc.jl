UW_fmt = FormatDesc(
  "UW (University of Washington)",
  "\"uw\"",
  "University of Washington, Seattle, WA, USA",
  "(a tarball that predates the World Wide Web)",
  "Steve Malone, Prof. Emeritus, steve@ess.washington.edu",
  HistVec(),
  ["event archival format consisting of a data file and an ASCII pick file",
  "the first line of a pick file is an event summary called an ACARD",
  "station file (human-maintained) needed for instrument locations",
  "developed by R. Crosson & son at UW, late 1970s",
  "maintained by R. Crosson, P. Lombard, and S. Malone through 2002"],
  ["Pacific Northwest Seismic Network",
  "Cascades Volcano Observatory",
  "volcano monitoring (northwestern United States)"],
  ["docs/uwdfif.pdf"],
  0xff
  )
UW_fmt.ver = [  FmtVer(2, "1996-06-02", false),
                FmtVer(1, "ca. 1978", nothing)
                ]
formats["uw"] = UW_fmt
