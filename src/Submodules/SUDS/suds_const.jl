# Code lists begin on page 322 of the SUDS manual
const unsupported = Int16.((3, 4, 8, 9, 11, 12, 13, 15, 16, 17, 18, 19, 21, 22, 23, 24))
const disp_only = Int16.((25, 26, 27, 28, 29, 31))

const suds_codes = Dict{Int64, String}(
  1   => "STATIONID",
  2   => "STRUCTTAG",
  3   => "PC_TERMINATOR",
  4   => "EQUIPMENT",
  5   => "STATIONCOMP",
  6   => "MUXDATA",
  7   => "DESCRIPTRACE",
  8   => "LOCTRACE",
  9   => "PC_CALIBRATION",
  10  => "FEATURE",
  11  => "RESIDUAL",
  12  => "PC_EVENT",
  13  => "EVDESCR",
  14  => "ORIGIN",
  15  => "ERROR",
  16  => "FOCALMECH",
  17  => "MOMENT",
  18  => "VELMODEL",
  19  => "LAYERS",
  20  => "PC_COMMENT",
  21  => "PROFILE",
  22  => "SHOTGATHER",
  23  => "CALIB",
  24  => "COMPLEX",
  25  => "TRIGGERS",
  26  => "TRIGSETTING",
  27  => "EVENTSETTING",
  28  => "DETECTOR",
  29  => "ATODINFO",
  30  => "TIMECORRECTION",
  32  => "CHANSET",
  31  => "INSTRUMENT",
  33  => "CHANSETENTRY"
  )

const sensor_types = Dict{UInt8, String}(
  0x42 => "K"         , # 'B' = "bolometer"
  0x43 => "{unknown}" , # 'C' = "local clock"
  0x48 => "%"         , # 'H' = "humidity"
  0x50 => "Pa"        , # 'P' = "pressure sensor"
  0x52 => "{unknown}" , # 'R' = "rainfall"
  0x53 => "m/m"       , # 'S' = "linear strain meter"
  0x54 => "K"         , # 'T' = "temperature sensor"
  0x56 => "m3/m3"     , # 'V' = "volumetric strain meter"
  0x57 => "{unknown}" , # 'W' = "wind"
  0x61 => "m/s2"      , # 'a' = "accelerometer"
  0x63 => "m"         , # 'c' = "creep meter"
  0x64 => "m"         , # 'd' = "displacement sensor"
  0x67 => "cm/s2"     , # 'g' = "gravimeter"
  0x69 => "degrees"   , # 'i' = "tilt meter/inclinometer"
  0x6d => "T"         , # 'm' = "magnetic field"
  0x72 => "{radon}"   , # 'r' = "radon sensor"
  0x73 => "{unknown}" , # 's' = "satellite time code"
  0x74 => "m"         , # 't' = "tidal meter"
  0x76 => "m/s"       , # 'v' = "velocity seismometer"
  0x77 => "N.m2"      , # 'w' = "torsion"
  0x78 => "{unknown}" , # 'x' = "experimental"
  )

const data_types = Dict{Int64, String}(
  -33 => "PAD4", -32 => "PAD2", -31 => "PAD1 ", -30 => "INT3", -29 => "IDXPTR ",
  -28 => "YESNO", -27 => "UCHAR ", -26 => "UINT2", -25 => "UINT4 ",
  -24 => "MEMPTR", -23 => "CHRPTR", -22 => "GENPTR", -21 => "CODESTR ",
  -20 => "INT2TM", -19 => "LIST", -18 => "LATIT", -17 => "LONGIT ",
  -16 => "MS i TIME", -15 => "ST i TIME", -14 => "FLOAT8", -13 => "FLOAT4 ",
  -12 => "AUTHOR", -11 => "DOMAIN", -10 => "REFERS2", -9 => "LABEL",
  -8 => "CODE4", -7 => "CODE2 ", -6 => "CODE1", -5 => "FIXED", -4 => "INT4",
  -3 => "INT2 ", -2 => "STRING", -1 => "CHAR", 2 => "structtag",
  3 => "pc i terminator", 4 => "equipment", 5 => "stationcomp", 6 => "muxdata",
  7 => "descriptrace", 8 => "loctrace", 9 => "pc i calibration",
  10 => "feature", 11 => "residual", 12 => "pc i event", 13 => "evdescr",
  14 => "origin", 15 => "error", 16 => "focalmech", 17 => "moment",
  18 => "velmodel", 19 => "layers", 20 => "pc i comment", 23 => "calib",
  25 => "triggers", 26 => "trigsetting", 27 => "eventsetting", 28 => "detector",
  29 => "atodinfo", 30 => "timecorrection", 31 => "instrument", 32 => "chanset",
  33 => "chansetentry", 104 => "sig i path i cmp", 105 => "signal i path",
  106 => "mux i waveform", 107 => "waveform", 108 => "data i group",
  109 => "response", 110 => "pick", 111 => "pick i residual", 112 => "event",
  113 => "signif i event", 114 => "solution", 115 => "solution i err",
  116 => "focal i mech", 118 => "vel i model", 119 => "vel i layer i data",
  123 => "resp i pz i data", 125 => "lsa i detection", 126 => "lsa i setting",
  130 => "clock i rate", 131 => "recorder", 200 => "variable i info",
  201 => "structure i info", 202 => "member i info", 203 => "stream",
  204 => "file i index", 205 => "code i list", 206 => "gui i default",
  211 => "comment", 212 => "structure i tag", 213 => "terminator",
  214 => "code i data", 300 => "site", 301 => "spectra",
  302 => "sig i cmp i data", 303 => "resp i fap i data",
  304 => "lsa i set i data", 305 => "resp i cfs i data",
  306 => "sig i path i data", 307 => "magnitude", 308 => "processing",
  309 => "polarity", 310 => "ssam i setup", 311 => "ssam i output",
  312 => "map i element", 313 => "seismometer", 314 => "resp i fir i data",
  315 => "filter", 316 => "sig i path i ass", 317 => "ssam i band i data",
  318 => "beam i data", 319 => "resp i sen i data", 320 => "calibration",
  321 => "source", 322 => "user i vars", 323 => "service",
  324 => "recorder i ass", 325 => "seismo i ass", 326 => "coordinate i sys"
  )

const pick_types = Dict{Int16, String}(
  0 => "NOT GIVEN",
  1 => "WINDOW",
  2 => "F FINIS",
  3 => "X MAXIMUM AMPLITUDE",
  4 => "INCREASE GAIN STEP",
  5 => "DECREASE GAIN STEP",
  50 => "P",
  51 => "P",
  52 => "P∗",
  53 => "PP",
  54 => "PPP",
  55 => "PPPP",
  56 => "PPS",
  57 => "PG",
  58 => "PN",
  59 => "PDIFFRACTED",
  60 => "PCP",
  61 => "PCPPKP",
  62 => "PCS",
  63 => "PP",
  64 => "PPP",
  65 => "PKP",
  66 => "PKPPKP",
  67 => "PKPPKS",
  68 => "PKPSKS",
  69 => "PKS",
  70 => "PPKS",
  71 => "PKKP",
  72 => "PKKS",
  73 => "PCPPKP",
  74 => "PCSPKP",
  100 => "S",
  101 => "S",
  102 => "S∗",
  103 => "SS",
  104 => "SSS",
  105 => "SSSS",
  106 => "SG",
  107 => "SN",
  108 => "SCS",
  109 => "SPCS",
  110 => "SS",
  111 => "SSS",
  112 => "SSSS",
  113 => "SSCS",
  114 => "SCSPKP",
  115 => "SCP",
  116 => "SKS",
  117 => "SKKS",
  118 => "SKKKS",
  119 => "SKSSKS",
  120 => "SKP",
  121 => "SKKP",
  122 => "SKKKP",
  201 => "LG",
  202 => "LR",
  203 => "LR2",
  204 => "LR3",
  205 => "LR4",
  206 => "LQ",
  207 => "LQ2",
  208 => "LQ3",
  209 => "LQ4",
  301 => "T")

# Instrument codes
# 0 = "not specified"
# 1 = "sp usgs"
# 2 = "sp wwssn"
# 3 = "lp wwssn"
# 4 = "sp dwwssn"
# 5 = "lp dwwssn"
# 6 = "hglp lamont"
# 7 = "lp hglp lamont"
# 8 = "sp sro"
# 9 = "lp sro"
# 10 = "sp asro"
# 11 = "lp asro"
# 12 = "sp rstn"
# 13 = "lp rstn"
# 1 4 = "sp uofa U of alaska"
# 15 = "STS-1/UVBB"
# 16 = "STS-1/VBB"
# 17 = "STS-2"
# 18 = "FBA-23"
# 19 = "Wilcoxin "
# 50 = "USGS cassette"
# 51 = "GEOS"
# 52 = "EDA"
# 53 = "Sprengnether refraction"
# 54 = "Teledyne refraction"
# 55 = "Kinemetrics refraction"
# 300 = "amplifier"
# 301 = "amp/vco"
# 302 = "filter"
# 303 = "summing amp"
# 304 = "transmitter"
# 305 = "receiver"
# 306 = "antenna"
# 307 = "battery"
# 308 = "solar cell"
# 309 = "discriminator"
# 310 = "discr. rack"
# 311 = "paper recorder"
# 312 = "film recorder"
# 313 = "smoked glass recorder"
# 314 = "atod converter"
# 315 = "computer"
# 316 = "clock"
# 317 = "time receiver"
# 318 = "magnetic tape"
# 319 = "magnetic disk"
# 320 = "optical disk"


# ampunits
# 'd' = "digital counts",
# 'm' = "millimeters on develocorder" ,
# 'n' = "nanometers (/sec or /sec/sec)",
# 'v' = "millivolts",

const auth = Dict{Int32, String}(
  0 => "none: not given" ,
  1 => "temp: Temporary, for testing purposes",
  2 => "suds: Internal to SUDS",
  101 => "calnet usgs menlo park, ca",
  102 => "alaska net usgs menlo park, ca" ,
  103 => "katmai net usgs menlo park, ca",
  104 => "scalnet usgs pasadena, ca.",
  120 => "shumagin net lamont palisades,ny",
  10000 => "gsmen: US Geological Survey, Menlo Park, CA",
  10001 => "suds: testing of suds at the USGS, Menlo Park, CA" ,
  10002 =>"calnt: network porcessing group, USGS, Menlo Park, CA",
  10005 => "5day: 5 day recorders US Geological Survey, Menlo Park, CA" ,
  10006 => "geos: GEOS recorders US Geological Survey, Menlo Park, CA",
  10007 => "cent: centipede recorders US Geological Survey, Menlo Park, CA" ,
  10008 => "citgs: CIT stations maintained by USGS, Menlo Park, CA",
  10009 => "lllgs: LLL stations maintained by USGS, Menlo Park, CA" ,
  10010 => "dwrgs: LLL stations maintained by USGS, Menlo Park, CA",
  10011 => "unrgs: UNR stations maintained by USGS, Menlo Park, CA",
  10012 => "yel: Yellowstone Park, Wyoming, maintained by USGS, Menlo Park, CA",
  10500 => "RTP: main rtp, USGS, Menlo Park",
  10501 => "PRTP: prototype rtp, USGS, Menlo Park",
  10502 => "MRTP: motorola rtp, USGS, Menlo Park" ,
  10503 => "TUST1: CUSP Tustin A/D #1",
  10504 => "TUST2: CUSP Tustin A/D #2" ,
  10505 => "ECLIP: CUSP Eclipse digitizer",
  10506 => "CVAX: CUSP-VAX/750 digitizer" ,
  10507 => "HPARK: Haliburton digital, Parkfield",
  10520 => "CITT1: Tustin #1, Pasadena",
  10521 => "CITT2: Tustin #2, Pasadena",
  10522 => "CITN3: 11/34 online, Pasadena" ,
  10523 => "CITS3: 11/34 online, Pasadena",
  10524 => "CITD1: Nova/Eclipse, Pasadena" ,
  10525 => "CITF: VAX, Pasadena",
  10526 => "CITH: hand timed in Pasadena" ,
  11000 => "Daiss, Charles, USGS, Menlo Park, CA",
  11001 => "Oppenheimer, Dave, USGS, Menlo Park, CA" ,
  11002 => "Eaton, Jerry, USGS, Menlo Park, CA",
  15000 => "gspas: US Geological Survey, Pasadena, CA" ,
  15001 => "tergp: TERRAscope, US Geological Survey, Pasadena, CA",
  20000 => "uofa: Geophysical Institute, University of Alaska, College, AK" ,
  30000 => "uofw: Geophysics, University of Washington, WA",
  40000 => "ldgo: Lamont Doherty Geological Observatory, Palisades, NY" ,
  50000 => "iris: IRIS Consortium, Seattle Data Center, WA",
  51000 => "gsn: Global Seismographic Network, USGS, Albuquerque, NM" ,
  52000 => "asro: Abbreviated Seismic Research Observatories",
  53000 => "passc: PASSCAL Program, IRIS",
  60000 => "lll: Lawrence Livermore Labs, Livermore, CA",
  70000 => "lbl: Lawrence Berkeley Labs, U. C. Berkeley, CA" ,
  80000 => "lanl: Los Alamos National Labs, Los Alamos, NM",
  90000 => "stl: St. Louis University, St. Louis, MO",
  100000 => "ucsd: University of California, San Diego and SCRIPPS",
  110000 => "ucb: University of California, Berkeley, CA",
  120000 => "ucsb: University of California, Santa Barbara, CA",
  130000 => "ucsc: University of California, Santa Cruz, CA",
  140000 => "usc: University of Southern California, Los Angeles, CA",
  150000 => "cit: California Institute of Technology, Pasadena, CA",
  150001 => "terct: TERRAscope network, California Institute of Technology, Pasadena, CA",
  160000 => "nnunr: Northern Nevada net, University of Nevada, Reno, NV",
  160001 => "snunr: Southern Nevada net, University of Nevada, Reno, NV",
  170000 => "utah: University of Utah, Salt Lake City, UT",
  180000 => "msu: Memphis State University, Memphis, TN",
  180000 => "msu: Memphis State University, Memphis, TN" ,
  181010 => "sanju: PANDA experiment in SAN JUAN, Argentina",
  181011 => "jujuy: PANDA experiment in JUJUY, Argentina",
  181020 => "newma: PANDA experiment in NEW MADRID, TN",
  181030 => "arken: PANDA experiment in AK",
  181040 => "hawii: PANDA experiment in HAWII",
  181050 => "palmn: PANDA experiment in PALMERSTON NORTH, New Zealand" ,
  181051 => "taran: PANDA2 experiment in mountain TARAMAKI, New Zealand",
  181060 => "taiwa: PANDA2 experiment in Taiwan",
  187000 => "archj: ARCH Johnston, professor, director of research",
  187001 => "jmch: Jer-Ming CHiu, professor",
  187002 => "wych: Wai-Ying CHung, associate research professor",
  187003 => "hjdo: H.James DOrman, executive director",
  187004 => "mell: Michael ELLis, associate professor",
  187005 => "Josep: JOSE Pujol, associate professor",
  187006 => "paulr: PAUL Rydelek, assistant research professor",
  187007 => "robsm: ROBert SMalley, assistant research professor" ,
  187008 => "paulb: PAUL Bodin, assistant professor",
  187009 => "eusc: EUgene SChweig, adjunct professor, USGS geologist" ,
  187010 => "johng: JOHN Geomberg, adjunct professor, USGS geophysicist",
  187011 => "scda: SCott DAvis, USGS guest researcher",
  187500 => "jimbo: JIM BOllwerk, seismic networks engineer",
  187501 => "stepb: STEPhen Brewer, ceri seismic networks director" ,
  187502 => "cchiu: Christy CHIU, research associate II",
  187503 => "michf: MICHael Frohme, director of computing",
  188000 => "zrli: ZhaoRen LI, graduate research assistant",
  188001 => "kcch: Kou-Cheng Chen, graduate research assistant" ,
  189000 => "group: data processing GROUP in ceri",
  190000 => "aftac: AFTAC Center for Seismic Studies, Alexandria, VA" ,
  200000 => "uhhil: University of Hawaii, Hilo, HA",
  210000 => "uhhon: University of Hawaii, Honolulu, HA" ,
  220000 => "mit: Massachusetts Institute of Technology, Cambridge, MA",
  230000 => "dtm: Department of Terrestrial Magnetism, Washington, DC" ,
  240000 => "vpi: Virginia Polytechnic Institute, Blacksburg, VA",
  250000 => "anu: Australian National University",
  260000 => "gsgol: US Geological Survey, Golden, CO",
  260001 => "nngsg: Northern Nevada network, US Geological Survey, Golden, CO" ,
  260002 => "sngsg: Southern Nevada network, US Geological Survey, Golden, CO",
  270000 => "bmr: Bureau of Mineral Resources",
  280000 => "cands: Canadian Digital Seismic Network",
  290000 => "cdsn: China Digital Seismic Network",
  300000 => "cdmg: California Division Mines-Geology, Sacramento, CA",
  310000 => "pge: Pacific Gas and Electric/Woodward-Clyde, CA",
  315001 => "unoiv: Union Oil, Imperial Valley, CA",
  315002 => "unoml: Union Oil, Medicine Lake",
  320000 => "terra: Terra Corporation, Mendocino, CA",
  330000 => "cadwr: California Division of Water Resources",
  340000 => "gikar: Geophysical Institute, Karlsruhe, Germany",
  350000 => "gfz: GeoForschungsZentrum, Potsdam, Germany",
  360000 => "cnrir: CNR-IRS, Milan, Italy",
  370000 => "gsc: Geological Survey of Canada, Ottawa, Canada" ,
  380000 => "ind: industry",
  385000 => "geot: Geotech, Garland, Texas",
  390000 => "nano: Nanometrics, Kanata, Ontario, Canada",
  395000 => "lenn: Lennartz Electronic, Tubingen, Germany",
  400000 => "kine: Kinemetrics, Pasadena, CA",
  405000 => "snl: Sandia National Laboratories, Albuquerque, NM",
  410000 => "cices: CICESE, Ensenada, Mexico",
  415000 => "nmt: New Mexico Inst Mining and Tech, Soccorro, NM"
)

const mag_scale = ("coda", "tau", "xmag", "ml", "mb", "ms", "mw")

# const mag_type = Dict{Char, String}(
# 'A' => "average coda and amplitude",
# 'S' => "Msz",
# 'a' => "amplitude",
# 'b' => "Mb",
# 'c' => "coda",
# 'l' => "Ml",
# 'm' => "moment",
# 's' => "Ms",
# 'w' = "Mw"
# )

const loc_prog = Dict{Char, String}(
'7' => "hypo71, Lee",
'e' => "hypoellipse, Lahr",
'i' => "hypoinverse, Klein",
'r' => "relp",
'u' => "Uhrhammer",
'c' => "centroid",
'h' => "hypo71"
)
