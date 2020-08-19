Silixa_fmt = FormatDesc(
  "Silixa TDMS",
  "\"silixa\"",
  "Silixa, Hertfordshire, UK",
  "adapted from https://silixa.com/resources/software-downloads/",
  "https://silixa.com/about-us/contact/",
  HistVec(),
  ["Silixa variant on NI LabVIEW TDMS file format"],
  ["Silixa (nodal array data)"],
  [""],
  0xfd
  )
Silixa_fmt.ver = [  FmtVer(1, "2018-06-28", false) ]
formats["Silixa TDMS"] = Silixa_fmt
