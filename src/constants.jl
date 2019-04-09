# Most constants are defined here
# Exceptions: SEED, KW

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
const dtconst = 62135683200000
const first_start = -62167219200
const hdrfields = [:id, :ot, :loc, :mag, :int, :mt, :np, :pax, :src, :notes, :misc]
const last_end = 253402257599
const show_os = 8
const sac_nul_f = -12345.0f0
const sac_nul_i = Int32(-12345)
const sac_nul_s = "-12345  "
const seisio_file_begin = UInt8[0x53, 0x45, 0x49, 0x53, 0x49, 0x4f]
const sep = Base.Filesystem.pathsep()
const sμ = 1000000.0
const vJulia = Float32(Meta.parse(string(VERSION.major,".",VERSION.minor)))
const vSeisIO = Float32(0.4)
const uw_dconv = -11676096000
const webhdr = Dict("UserAgent" => "Julia-SeisIO-FSDN.jl/0.1.3")
const μs = 1.0e-6

unsep = Sys.iswindows() ? "/" : "\\" # the un-separator; which of /, \ is NOT likely to show up in a glob
const regex_chars = String[unsep, "\$", "(", ")", "+", "?", "[", "\\0",
"\\A", "\\B", "\\D", "\\E", "\\G", "\\N", "\\P", "\\Q", "\\S", "\\U", "\\U",
"\\W", "\\X", "\\Z", "\\a", "\\b", "\\c", "\\d", "\\e", "\\f", "\\n", "\\n",
"\\p", "\\r", "\\s", "\\t", "\\w", "\\x", "\\x", "\\z", "]", "^", "{", "|", "}"]
