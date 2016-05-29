using SeisIO

# Get version
function getSLver(vline)
  # Versioning (function getver) will break if SeedLink ever switches to a VV.PPP.NNN format
  ver = 0.0
  vinfo = split(vline)
  for i in vinfo
    if startswith(i, 'v')
      try
        ver = parse(i[2:end])
        return ver
      end
    end
  end
end

# Deal with with OK\r\n spammmm + implicit Julia blocking
# Doesn't correctly handle extended replies, but the beauty of an interpreted
# language is that you can always fix your syntax and try again.
function not_ok(conn)
  c ="K".data[1]
  OK = "OK\r\n".data
  while c in OK
    c = read(conn, UInt8)
    eof(conn) && sleep(1)
  end
  return c
end

# SeedLink "TIME" mode
function sltime(S, conn, chans, patts, sstr, tstr, maxbuf; v=false::Bool, vv=false::Bool)
  for s = 1:length(chans)
    isempty(patts[s]) || write(conn, string("SELECT ", patts[s], "\r"))
    write(conn, string("STATION ", chans[s], "\rTIME ", sstr, " ", tstr, "\r"))
  end
  write(conn, "END\r")

  # Buffer copy seems like the fastest "safe" approach in Julia
  buf = IOBuffer(maxbuf)

  # Begin receiving data
  c = not_ok(conn) # Will always return 'S' for good data
  vv && println("c = ", Char(c))
  Char(c) == 'E' && error(@sprintf("Malformed channel or pattern spec (check manually):\nchans = %s\npatts = %s\n", chans, patts))
  write(buf, c)
  write(buf, read(conn,UInt8,7))
  while true
    n = 0
    while eof(conn)
      n += 1
      try
        vv && println("Single-char read")
        write(buf, read(conn,UInt8))
        break
      catch
        vv && println("sleep(1)")
        sleep(1)
        n > 60 && error("Too many retries, exit w/error.")
      end
    end
    try
      write(buf, read(conn.buffer,UInt8,520-rem(position(buf),520)))
    catch
      if v || vv
        println("Connection closed, clearing buffer and exiting.")
      end
      parsesl(S, buf, v=true)
      break
    end
    if position(buf) == maxbuf
      parsesl(S, buf)
      seekstart(buf)
    end
  end
  close(buf)
  close(conn)
  return S
end

"""
    S = SeedLink(chanlist)

Retrieve real-time data via. SeedLink in TIME mode for channels specified by
ASCII array chanlist. See documentation for keyword options.
"""
function SeedLink(chans::Array{ASCIIString,1};
  addr="rtserve.iris.washington.edu"::ASCIIString,
  port=18000::Integer,
  patts=["*"]::Array{ASCIIString,1},
  mode="TIME"::ASCIIString,   # only "TIME" is currently supported
  s=0.0::Float64,             # start time. Set to 0.0 for "current second"
  t=120.0::Float64,           # time length (seconds).
  to=60::Real,                # timeout (seconds)
  N=32::Integer,              # N 512-byte packets are buffered before each conversion call
  v=false::Bool,              # verbose mode
  vv=false::Bool,             # very verbose mode
  y=true::Bool)

  # Match empty pattern lists
  if patts[1] == "*"
    patts = repmat([""], length(chans))
  end

  maxbuf = N*520
  S = SeisData()

  # Create connection
  sock = TCPSocket()
  sock.line_buffered = false
  conn = connect(sock,addr,port)

  # Get version, server info
  write(conn,"HELLO\r")
  vline = readline(conn)
  sline = readline(conn)
  ver = getSLver(vline)
  vv && println("Version = ", ver)
  vv && println("Server = ", strip(sline,['\r','\n']))

  N = length(chans)
  if ver < 2.5 && isa(chans, Array{ASCIIString,1})
    error(@sprintf("Multi-station mode unsupported in SeedLink v%.1f", ver))
  elseif ver < 2.92 && mode == "TIME"
    error(@sprintf("Mode \"TIME\" not available in SeedLink v%.1f", ver))
  end
  ts = s == 0.0 ? floor(time()) : s
  tt = ts + t
  ts = Dates.unix2datetime(ts)
  tt = Dates.unix2datetime(tt)
  sstr = join([Dates.Year(ts).value,
               Dates.Month(ts).value,
               Dates.Day(ts).value,
               Dates.Hour(ts).value,
               Dates.Minute(ts).value,
               Dates.Second(ts).value],',')
  tstr = join([Dates.Year(tt).value,
               Dates.Month(tt).value,
               Dates.Day(tt).value,
               Dates.Hour(tt).value,
               Dates.Minute(tt).value,
               Dates.Second(tt).value],',')
  if mode == "TIME"
    if v || vv
      println("Station commands to send:")
      for s = 1:length(chans)
        isempty(patts[s]) || println("write(conn,\"SELECT ", patts[s], "\\r\")")
        println("write(conn,\"STATION ", chans[s], "\\rTIME ", sstr, " ", tstr, "\\r\")")
      end
    end
  sltime(S, conn, chans, patts, sstr, tstr, maxbuf, v=v, vv=vv)
  for i = 1:S.n
    S.src[i] = "seedlink"
    note(S, i, "SeedLink server was "*addr*":"*string(port))
  end
  if y
    return sync!(S, s="min", t=t)
  else
    return S
  end
  # Data mode will simply replace the command with "data" and launch as a coroutiune
  end
end

"""
    SeedLink("config_file")

Retrieve real-time data via. SeedLink in TIME mode for channels specified in
file config_file. See documentation for keyword options.
"""
function SeedLink(config_file::ASCIIString;
  addr="rtserve.iris.washington.edu"::ASCIIString,
  port=18000::Integer,
  mode="TIME"::ASCIIString,
  s=0.0::Float64,
  t=120.0::Float64,
  N=32::Integer,
  to=60::Real,
  v=false::Bool,
  vv=false::Bool,
  y=true::Bool)

  !isfile(config_file) && error("First argument must be a string array or config filename")
  conf = filter(i -> !startswith(strip(i, ['\r', '\n']), ['\#','\*']), open(readlines, config_file))
  chans = Array{ASCIIString,1}()
  patts = Array{ASCIIString,1}()
  for i = 1:length(conf)
    try
      (net, sta, sel) = split(strip(conf[i],['\r','\n']), ' ', limit=3)
      ch = join([sta, net],' ')
      if isempty(sel)
        push!(chans, ch)
        push!(patts, "")
      else
        sel = collect(split(strip(sel), ' '))
        for j = 1:length(sel)
          push!(chans, ch)
          push!(patts, sel[j])
        end
      end
    catch
      (net, sta) = split(strip(conf[i],['\r','\n']), ' ')
      push!(chans,net)
      push!(patts,"")
    end
  end
  S = SeedLink(chans, patts=patts, addr=addr, port=port, mode=mode, s=s, t=t, N=N, v=v, vv=vv, y=y)
  return S
end
