# Most constants are defined here
# Exceptions: BUF, KW

const bad_chars = Dict{String,Array{UInt8,1}}(
  "File" => [0x22, 0x24, 0x2a, 0x2f, 0x3a, 0x3c, 0x3e, 0x3f, 0x40, 0x5c, 0x5e, 0x7c, 0x7e, 0x7f],
  "HTML" => [0x22, 0x26, 0x27, 0x3b, 0x3c, 0x3e, 0xa9, 0x7f],
  "Julia" => [0x24, 0x5c, 0x7f],
  "Markdown" => [0x21, 0x23, 0x28, 0x29, 0x2a, 0x2b, 0x2d, 0x2e, 0x5b, 0x5c, 0x5d, 0x5f, 0x60, 0x7b, 0x7d],
  "SEED" => [0x2e, 0x7f],
  "Strict" => [0x20, 0x21, 0x22, 0x23, 0x24, 0x25, 0x26, 0x27, 0x28, 0x29, 0x2a,
               0x2b, 0x2c, 0x2d, 0x2e, 0x2f, 0x3a, 0x3b, 0x3c, 0x3d, 0x3e, 0x3f,
               0x40, 0x5b, 0x5c, 0x5d, 0x5e, 0x60, 0x7b, 0x7c, 0x7d, 0x7e, 0x7f] )
const datafields = [:id, :name, :loc, :fs, :gain, :resp, :units, :src, :notes, :misc, :t, :x]
const days_per_month = Int32[31,28,31,30,31,30,31,31,30,31,30,31]
const days_per_month_leap = Int32[31,29,31,30,31,30,31,31,30,31,30,31]
const dtconst = 62135683200000000
const first_start = -62167219200
const hdrfields = [:id, :ot, :loc, :mag, :int, :mt, :np, :pax, :src, :notes, :misc]
const id_positions = Int8[11, 12, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
const id_spacer = 0x2e
const last_end = 253402257599
const show_os = 8
const sac_keys = (  String[ "delta", "depmin", "depmax", "scale", "odelta",
                            "b", "e", "o", "a", "internal1",
                            "t0", "t1", "t2", "t3", "t4",
                            "t5", "t6", "t7", "t8", "t9",
                            "f", "resp0", "resp1", "resp2", "resp3",
                            "resp4", "resp5", "resp6", "resp7", "resp8",
                            "resp9", "stla", "stlo", "stel", "stdp",
                            "evla", "evlo", "evel", "evdp", "mag",
                            "user0", "user1", "user2", "user3", "user4",
                            "user5", "user6", "user7", "user8", "user9",
                            "dist", "az", "baz", "gcarc", "internal2",
                            "internal3", "depmen", "cmpaz", "cmpinc", "xminimum",
                            "xmaximum", "yminimum", "ymaximum", "unused1", "unused2",
                            "unused3", "unused4", "unused5", "unused6", "unused7" ],
                    String[ "nzyear", "nzjday", "nzhour", "nzmin", "nzsec",
                            "nzmsec", "nvhdr", "norid", "nevid", "npts",
                            "internal4", "nwfid", "nxsize", "nysize", "unused8",
                            "iftype", "idep", "iztype", "unused9", "iinst",
                            "istreg", "ievreg", "ievtyp", "iqual", "isynth",
                            "imagtyp", "imagsrc", "unused10", "unused11", "unused12",
                            "unused13", "unused14", "unused15", "unused16", "unused17",
                            "leven", "lpspol", "lovrok", "lcalda", "unused18" ],
                    String[ "kstnm", "kevnm", "khole", "ko", "ka", "kt0", "kt1", "kt2",
                            "kt3", "kt4", "kt5", "kt6", "kt7", "kt8", "kt9", "kf", "kuser0",
                            "kuser1", "kuser2", "kcmpnm", "knetwk", "kdatrd", "kinst" ] )
const sac_nul_f = -12345.0f0
const sac_nul_i = Int32(-12345)
const sac_nul_start = 0x2d
const sac_nul_Int8 = Int8[0x31, 0x32, 0x33, 0x34, 0x35]
const segy_ftypes  = Array{DataType, 1}([UInt32, Int32, Int16, Any, Float32, Any, Any, Int8]) # Note: type 1 is IBM Float32
const seisio_file_begin = UInt8[0x53, 0x45, 0x49, 0x53, 0x49, 0x4f]
const sep = Base.Filesystem.pathsep()
const steim = reverse(collect(0x00000000:0x00000002:0x0000001e), dims=1)
const sμ = 1000000.0
const vJulia = Float32(Meta.parse(string(VERSION.major,".",VERSION.minor)))
const vSeisIO = Float32(0.4)
const uw_dconv = -11676096000000000
const webhdr = Dict("UserAgent" => "Julia-SeisIO-FSDN.jl/0.2.0")
const μs = 1.0e-6

unsep = Sys.iswindows() ? "/" : "\\" # the un-separator; which of /, \ is NOT likely to show up in a glob
const regex_chars = String[unsep, "\$", "(", ")", "+", "?", "[", "\\0",
"\\A", "\\B", "\\D", "\\E", "\\G", "\\N", "\\P", "\\Q", "\\S", "\\U", "\\U",
"\\W", "\\X", "\\Z", "\\a", "\\b", "\\c", "\\d", "\\e", "\\f", "\\n", "\\n",
"\\p", "\\r", "\\s", "\\t", "\\w", "\\x", "\\x", "\\z", "]", "^", "{", "|", "}"]
