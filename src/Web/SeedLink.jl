using SeisIO

function parsesl!(S::SeisData, buf::IOBuffer; v=false::Bool, vv=false::Bool)
  seekstart(buf)
  if v || vv
    @printf(STDOUT, "Parsing: ")
  end
  while !eof(buf)
    if v || vv
      id = String(read(buf,UInt8,8))
      @printf(STDOUT, "%s, ", id)
    else
      skip(buf, 8)
    end
    parserec(S, buf, v=v, vv=vv)
  end
  return(S)
end

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

# Deal with with OK\r\n + implicit Julia blocking
function not_ok(conn)
  c ="K".data[1]
  OK = "OK\r\n".data
  while c in OK
    eof(conn)
    c = read(conn, UInt8)
  end
  return c
end

# SeedLink "TIME" mode
function sltime(conn, chans::Array{String,1}, patts::Array{String,1}, sstr::String, tstr::String, maxbuf::Integer;
  v=false::Bool,
  vv=false::Bool,
  w=false::Bool)

  S = SeisData()
  for s = 1:length(chans)
    str = ""
    if isempty(patts[s])
      str *= string("SELECT ?????.D\r")
    else
      str *= string("SELECT ", patts[s], "\r")
    end
    str *= string("STATION ", chans[s], "\rTIME ", sstr, " ", tstr, "\r")
    vv && println("Sending string to server: ", replace(str,"\r","\\r"))
    write(conn, str)

    # We expect exactly 2 lines back
    r1 = readline(conn)
    r2 = readline(conn)
    vv && @printf(STDOUT, "Response to SELECT query = %sResponse to STATION query = %s", r1, r2)
  end
  write(conn,"END\r")

  # Create a file for raw packet dump
  if w
    fname = hashfname([join(chans,','), join(patts,','), sstr, tstr], "mseed")
    open(fname, "w")
  end

  # Buffer copy seems like the fastest "safe" approach in Julia
  buf = IOBuffer(maxbuf)

  # Begin receiving data
  c = not_ok(conn)                      # Always 'S' for good data
  vv && println("c = ", Char(c))
  Char(c) == 'E' && error(@sprintf("Malformed channel or pattern spec (check manually):\nchans = %s\npatts = %s\n", chans, patts))

  write(buf, c)
  write(buf, read(conn, UInt8, 519))
  n = 1
  @printf(STDOUT, "Total packets buffered: %5i", n)
  while true
    eof(conn)
    try
      write(buf, read(conn, UInt8, 520))
      if vv
        n+=1
        @printf(STDOUT, "\b\b\b\b\b%5i", n)
      end
    catch
      if eof(conn)
        vv && @printf(STDOUT, "...done.\n")
        (v || vv) && println("Connection closed, clearing buffer and exiting.")
        parsesl!(S, buf, v=v, vv=vv)
        break
      else
        c = read(conn, UInt8)
        if char(c) == 'E'
          read(conn, UInt8, 2)
        else
          write(buf, c)
        end
      end
    end
    if position(buf) == maxbuf
      if w
        seekstart(buf)
        write(fname, buf)
      end
      parsesl!(S, buf, v=v, vv=vv)
      seekstart(buf)
    end
  end
  close(buf)
  close(conn)
  w && close(fname)
  return S
end

"""
    S = SeedLink(chanlist)

Retrieve real-time data via. SeedLink in TIME mode for channels specified by
ASCII array chanlist. See documentation for keyword options.
"""
function SeedLink(chans::Array{String,1};
  addr="rtserve.iris.washington.edu"::String,
  port=18000::Integer,
  patts=["*"]::Array{String,1},
  mode="TIME"::String,        # only "TIME" is currently supported
  s=0::Union{Real,DateTime,String},
  t=300::Union{Real,DateTime,String},
  to=60::Real,                # timeout (seconds)
  N=1024::Integer,            # N 512-byte packets are buffered before each conversion call
  v=false::Bool,              # verbose mode
  vv=false::Bool,             # very verbose mode
  w=false::Bool,              # write raw packets to disk
  y=true::Bool)
  
  # Match empty pattern lists
  if patts[1] == "*"
    patts = repmat([""], length(chans))
  end

  maxbuf = N*520

  # Create connection
  sock = TCPSocket()
  conn = connect(sock,addr,port)

  # Get version, server info
  write(conn,"HELLO\r")
  vline = readline(conn)
  sline = readline(conn)
  ver = getSLver(vline)
  vv && println("Version = ", ver)
  vv && println("Server = ", strip(sline,['\r','\n']))

  N = length(chans)
  if ver < 2.5 && isa(chans, Array{String,1})
    error(@sprintf("Multi-station mode unsupported in SeedLink v%.1f", ver))
  elseif ver < 2.92 && mode == "TIME"
    error(@sprintf("Mode \"TIME\" not available in SeedLink v%.1f", ver))
  end
  if mode == "TIME"
    (d0,d1) = parsetimewin(s,t)
    if (d1-u2d(time())).value < 0
      warn("End time before present; SeedLink may behave badly!")
    end
    sstr = join(split(string(d0),r"[\-T\:\.]")[1:6],',')
    tstr = join(split(string(d1),r"[\-T\:\.]")[1:6],',')
    if v || vv
      println("Station commands to send:")
      for c = 1:length(chans)
        isempty(patts[c]) || println("write(conn,\"SELECT ", patts[c], "\\r\")")
        println("write(conn,\"STATION ", chans[c], "\\rTIME ", sstr, " ", tstr, "\\r\")")
      end
    end
    S = sltime(conn, chans, patts, sstr, tstr, maxbuf, v=v, vv=vv, w=w)
    for i = 1:S.n
      S.src[i] = "seedlink"
      note(S, i, "SeedLink server was "*addr*":"*string(port))
    end
    if y
      return sync!(S, s=d0, t=d1)
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
function SeedLink(config_file::String;
  addr="rtserve.iris.washington.edu"::String,
  port=18000::Integer,
  mode="TIME"::String,
  s=0::Union{Real,DateTime,String},
  t=300::Union{Real,DateTime,String},
  N=32::Integer,
  to=60::Real,
  v=false::Bool,
  vv=false::Bool,
  w=false::Bool,
  y=true::Bool)

  !isfile(config_file) && error("First argument must be a string array or config filename")
  conf = filter(i -> !startswith(strip(i, ['\r', '\n']), ['\#','\*']), open(readlines, config_file))
  chans = Array{String,1}()
  patts = Array{String,1}()
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
  S = SeedLink(chans, patts=patts, addr=addr, port=port, mode=mode, s=s, t=t, N=N, v=v, vv=vv, y=y, w=w)
  return S
end
