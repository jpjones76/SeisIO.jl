export guess

function guess_ftype(io::IO, swap::Bool, sz::Int64, v::Int64)
  str = String[]

  # =========================================================================
  # Robust file tests: exact "magic number", start sequence, etc....

  # AH-2 --------------------------------------------------------------------
  seekstart(io)
  try
    mn = (swap ? bswap : identity)(read(io, Int32))
    @assert mn == 1100
    push!(str, "ah2")
  catch err
    (v > 2) && @warn(string("Test for AH-2 threw error:", err))
  end

  # Bottle ------------------------------------------------------------------
  seekstart(io)
  try
    ms = (swap ? bswap : identity)(read(io, Int16))
    @assert ms == 349
    skip(io, 2)
    @assert (swap ? bswap : identity)(read(io, Int32)) == 40
    @assert (swap ? bswap : identity)(read(io, Float64)) > 0.0
    @assert (swap ? bswap : identity)(read(io, Float32)) > 0.0f0
    @assert (swap ? bswap : identity)(read(io, Int32)) > 0
    @assert (swap ? bswap : identity)(read(io, Int32)) in (0, 1, 2)
    push!(str, "bottle")
  catch err
    (v > 2) && @warn(string("Test for Bottle threw error:", err))
  end

  # GeoCSVm Lennartz ASCII --------------------------------------------------
  seekstart(io)
  try
    line = readline(io)
    @assert eof(io) == false
    if occursin("GeoCSV", line)
      while startswith(line, "#")
        line = readline(io)
      end
      if length(split(line)) == 2
        push!(str, "geocsv")
      else
        push!(str, "geocsv.slist")
      end
    else hdr = split(line)
      if hdr[2] == "station"
        push!(str, "lennasc")
      end
    end
  catch err
    (v > 2) && @warn(string("Test for GeoCSV threw error:", err))
  end


  # SUDS --------------------------------------------------------------------
  seekstart(io)
  try
    @assert read(io, UInt8) == 0x53
    @assert iscntrl(Char(read(io, UInt8))) == false
    sid = (swap ? bswap : identity)(read(io, Int16))
    nbs = (swap ? bswap : identity)(read(io, Int32))
    nbx = (swap ? bswap : identity)(read(io, Int32))
    @assert zero(Int16) ≤ sid < Int16(34) # should be in range 1:33
    @assert nbs > zero(Int32)
    @assert nbx ≥ zero(Int32)
    push!(str, "suds")

  catch err
    (v > 2) && @warn(string("test for SUDS threw error:", err))
  end

  # mSEED -------------------------------------------------------------------
  seekstart(io)
  try
    # Sequence number is numeric
    seq = Char.(read(io, 6))
    @assert(all(isnumeric.(seq)))

    # Next character is one of 'D', 'R', 'M', 'Q'
    @assert read(io, UInt8) in (0x44, 0x52, 0x4d, 0x51)
    push!(str, "mseed")


  catch err
    (v > 2) && @warn(string("test for mini-SEED threw error:", err))
  end

  # # FDSN station XML ---------------------------------------------------------
  # seekstart(io)
  # try
  #   @assert occursin("FDSNStationXML", String(read(io, 255)))
  #   push!(str, "sxml")
  # catch err
  #   (v > 2) && @warn(string("test for station XML threw error:", err))
  # end
  #
  # # SEED RESP ---------------------------------------------------------------
  # seekstart(io)
  # try
  #   line = readline(io)
  #   @assert eof(io) == false
  #   for i = 1:6
  #     while startswith(line, "#")
  #       line = readline(io)
  #     end
  #     @assert startswith(line, "B0")
  #   end
  #   push!(str, "resp")
  # catch err
  #   (v > 2) && @warn(string("test for SEED RESP threw error:", err))
  # end

  # =========================================================================
  # Non-robust file tests: exact "magic number", start sequence, etc....
  ((v > 0) && isempty(str)) && @info("file has no unique identifier; checking content.")

  # AH-1 --------------------------------------------------------------------
  seekstart(io)
  try
    skip(io, 12)
    mn = (swap ? bswap : identity)(read(io, Int32))
    @assert mn == 6
    skip(io, 8)
    mn = (swap ? bswap : identity)(read(io, Int32))
    @assert mn == 8
    seek(io, 700)
    mn = (swap ? bswap : identity)(read(io, Int32))
    @assert mn == 80
    seek(io, 784)
    mn = (swap ? bswap : identity)(read(io, Int32))
    @assert mn == 202
    push!(str, "ah1")

  catch err
    (v > 2) && @warn(string("test for AH-1 threw error:", err))
  end

  # SAC ---------------------------------------------------------------------
  seekstart(io)
  try
    autoswap = should_bswap(io)
    seekstart(io)
    delta = (autoswap ? bswap : identity)(read(io, Float32))
    @assert delta ≥ 0.0f0
    seek(io, 280)
    tt = (autoswap ? bswap : identity).(read!(io, zeros(Int32, 5)))
    @assert tt[1] > 1900
    @assert 0 < tt[2] < 367
    @assert -1 < tt[3] < 24
    @assert -1 < tt[4] < 60
    @assert -1 < tt[5] < 60
    push!(str, "sac")

  catch err
    (v > 0) && @warn(string("test for SAC threw error:", err))
  end

  # SEGY --------------------------------------------------------------------
  seekstart(io)
  try
    seek(io, 3212)
    shorts = (swap ? bswap : identity).(read!(io, zeros(Int16, 12)))
    @assert shorts[3] > zero(Int16)               # sample interval in μs
    @assert shorts[5] ≥ zero(Int16)               # number of samples per trace
    @assert shorts[7] in one(Int16):Int16(8)      # data format code
    seek(io, 3501)
    @assert (swap ? bswap : identity)(read(io, UInt16)) in 0x0000:0x0200    # SEGY version number
    @assert (swap ? bswap : identity)(read(io, Int16)) ≥ zero(Int16)        # trace length; 0 = variable
    push!(str, "segy")

  catch err
    (v > 0) && @warn(string("test for SEGY threw error:", err))
  end

  # UW ----------------------------------------------------------------------
  seekstart(io)
  try
    N = (swap ? bswap : identity)(read(io, Int16))
    @assert N ≥ zero(Int16)
    [@assert (swap ? bswap : identity)(read(io, Int32)) ≥ zero(Int32) for i = 1:4]
    skip(io, 26)
    @assert read(io, UInt8) in (0x20, 0x31, 0x32)
    seekend(io)
    skip(io, -4)
    nstructs = (swap ? bswap : identity)(read(io, Int32))
    (v > 2) && println("nstructs = ", nstructs)
    @assert nstructs ≥ zero(Int32)
    @assert (12*nstructs)+4 < position(io)
    push!(str, "uw")

  catch err
    (v > 2) && @warn(string("test for UW threw error:", err))
  end

  # Win32 -------------------------------------------------------------------
  seekstart(io)
  try
    date_arr = zeros(Int64, 6)
    skip(io, 4)
    date_hex = read(io, 8)
    t_new = datehex2μs!(date_arr, date_hex)
    (v > 2) && println(u2d(t_new*1.0e-6))
    @assert t_new > 0
    skip(io, 4)
    nb = (swap ? bswap : identity)(read(io, UInt32))
    @assert (nb + position(io)) ≤ sz
    skip(io, 4)
    V = (swap ? bswap : identity)(read(io, UInt16))
    C = UInt8(V >> 12)
    N = V & 0x0fff
    @assert C in 0x00:0x04
    @assert 0x0000 < N < 0x0066 # No station in Japan samples above 100 Hz
    push!(str, "win32")

  catch err
    (v > 2) && @warn(string("test for win32 threw error:", err))
  end

  # PASSCAL -----------------------------------------------------------------
  seekstart(io)
  try
    seek(io, 114)
    nx = (swap ? bswap : identity)(read(io, Int16))
    dt = (swap ? bswap : identity)(read(io, Int16))
    seek(io, 156)
    yy = (swap ? bswap : identity)(read(io, Int16))
    jj = (swap ? bswap : identity)(read(io, Int16))
    @assert yy in Int16(1950):Int16(3000)
    @assert jj in one(Int16):Int16(366)

    if dt == typemax(Int16)
      seek(io, 200)
      dt = (swap ? bswap : identity)(read(io, Int32))
    end
    if nx == typemax(Int16)
      seek(io, 228)
      nx = (swap ? bswap : identity)(read(io, Int32))
    end
    @assert dt > zero(Int32)
    @assert nx > zero(Int32)
    push!(str, "passcal")

  catch err
    (v > 2) && @warn(string("test for PASSCAL threw error:", err))
  end

  return str
end

@doc """
    function guess(fname[, v=V])

Try to guess the file type of file `fname`. Keyword `v` controls verbosity.
Only recognizes file formats supported by SeisIO.read_data.

Returns a tuple: (ftype::String, swap::Bool)
* `ftype` is the file type string to pass to `read_data`, except in these cases:
  + if ftype == "unknown", guess couldn't identify the file type.
  + if ftype begins with "!" and contains a comma-separated list, the file type
* `swap` determines whether or not file should be byte-swapped by `read_data`.
Generally `swap=true` for big-Endian files, with two exceptions:
  wasn't determined uniquely.
  + in SAC and mini-SEED, tests for endianness are built into the file format,
  so the value of `swap` is irrelevant.
  + if ftype = "unknown", swap=nothing.

!!! warning

    `guess` cannot identify SACPZ files from content alone.

!!! danger

    false positives are possible with file formats outside the scope of SeisIO.

""" guess
function guess(file::String; v::Int64=KW.v)
  safe_isfile(file) || error("File not found!")

  sz = stat(file).size
  io = open(file, "r")
  str_le = guess_ftype(io, false, sz, v)
  str_be = guess_ftype(io, true, sz, v)
  close(io)

  swap = false
  if length(str_le) == 0 && length(str_be) == 0
    ftype = ["unknown"]
  elseif length(str_be) == 0
    ftype = str_le
  elseif length(str_le) == 0
    swap = true
    ftype = str_be
  else
    if str_le == str_be
      swap = false
      ftype = str_le
    else
      swap = nothing
      ftype = unique(vcat(str_le, str_be))
    end
  end
  fstr = length(ftype) > 1 ? "!"*join(ftype, ",") : ftype[1]
  return (fstr, swap)
end
