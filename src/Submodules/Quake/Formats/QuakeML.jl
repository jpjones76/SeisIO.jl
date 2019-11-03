function get_RealQuantity(xmle::LightXML.XMLElement, str::String)
  dx = 0.0
  x = 0.0
  for z in child_elements(xmle)
    if name(z) == str
      for y in child_elements(z)
        if name(y) == "value"
          x = parse(Float64, content(y))
        elseif name(y) == "uncertainty"
          dx = parse(Float64, content(y))
        end
      end
    end
  end
  return (x, dx)
end

function parse_qml(evt::XMLElement)
  MT = Array{SeisSrc,1}(undef, 0)
  evt_src = attribute(evt, "publicID")
  evt_id = split(evt_src, r"[;:/=]")[end]
  preferredOriginID = ""
  preferredMagnitudeID = ""
  preferredFocalMechanismID = ""

  mags = Array{XMLElement,1}(undef,0)
  origs = Array{XMLElement,1}(undef,0)
  mechs = Array{XMLElement,1}(undef,0)
  eqtype = ""

  for ch in child_elements(evt)
    cn = name(ch)
    if cn == "preferredOriginID"
      preferredOriginID = split(content(ch), r"[;:/=]")[end]
    elseif cn == "preferredMagnitudeID"
      preferredMagnitudeID = split(content(ch), r"[;:/=]")[end]
    elseif cn == "preferredFocalMechanismID"
      preferredFocalMechanismID = split(content(ch), r"[;:/=]")[end]
    elseif cn == "type"
      eqtype = content(ch)
    elseif cn == "magnitude"
      push!(mags, ch)
    elseif cn == "origin"
      push!(origs, ch)
    elseif cn == "focalMechanism"
      push!(mechs, ch)
    end
  end

  # ==========================================================================
  # Focal Mechanism
  n = 0
  while n < length(mechs)
    n         = n+1
    auth      = ""
    mech      = getindex(mechs, n)
    np        = zeros(Float64, 3, 2)
    pax       = zeros(Float64, 3, 3)
    mt        = zeros(Float64, 6)
    dm        = fill!(zeros(Float64, 6), Inf)

    # generate SeisSrc object
    S = SeisSrc()
    ssrc = attribute(mech, "publicID")
    setfield!(S, :id, String(split(ssrc, r"[;:/=]")[end]))

    for child in child_elements(mech)
      cname = name(child)

      if cname == "creationInfo"
        for grandchild in child_elements(child)
          if name(grandchild) ==  "author"
            auth = content(grandchild)
          end
        end

      elseif cname == "azimuthalGap"
        setfield!(S, :gap, parse(Float64, content(child)))

      elseif cname == "stationPolarityCount"
        setfield!(S, :npol, parse(Int64, content(child)))

      elseif cname == "nodalPlanes"
        j = 0
        for np2 in child_elements(child)  # nodalPlane1, nodalPlane2
          if name(np2) != "preferredPlane"
            for grandchild in child_elements(np2) # strike, dip, rake
              for greatgrandchild in child_elements(grandchild)
                if name(greatgrandchild) == "value"
                  j = j+1
                  setindex!(np, parse(Float64, content(greatgrandchild)), j)
                end
              end
            end
          end
        end
        S.misc["planes_desc"] = "strike, dip, rake"

      elseif cname == "principalAxes"
        j = 0
        for grandchild in child_elements(child) # tAxis, pAxis, nAxis
          for greatgrandchild in child_elements(grandchild) # azimuth, plunge, length
            for redheadedstepchild in child_elements(greatgrandchild)
              if name(redheadedstepchild) == "value"
                j = j+1
                setindex!(pax, parse(Float64, content(greatgrandchild)), j)
              end
            end
          end
        end
        S.misc["pax_desc"] = "azimuth, plunge, length"

      elseif cname == "momentTensor"
        S.misc["mt_id"] = attribute(child, "publicID")
        for a in child_elements(child)
          aname = name(a)
          if aname == "scalarMoment"
            setfield!(S, :m0, parse(Float64, content(a)))
          elseif aname == "tensor"
            j = 0
            for k in ("Mrr", "Mtt", "Mpp", "Mrt", "Mrp", "Mtp")
              j = j+1
              (mt[j], dm[j]) = get_RealQuantity(a, k)
            end
          elseif aname == "sourceTimeFunction"
            for b in child_elements(a)
              if name(b) == "type"
                S.st.desc = content(b)
              elseif name(b) == "duration"
                S.st.dur = parse(Float64, content(b))
              elseif name(b) == "riseTime"
                S.st.rise = parse(Float64, content(b))
              elseif name(b) == "decayTime"
                S.st.decay = parse(Float64, content(b))
              end
            end
          elseif aname == "derivedOriginID"
            S.misc["derivedOriginID"] = String(split(content(a), r"[;:/=]")[end])
            S.misc["xmt_derivedOriginID"] = string(a)
          else
            S.misc["xmt_" * aname] = string(a)
          end
        end
      elseif cname == "methodID"
        S.misc["methodID"] = content(child)
      else
        S.misc["xmech_" * cname] = string(child)
      end

    end
    setfield!(S, :planes, np)
    setfield!(S, :pax, pax)
    setfield!(S, :mt, mt)
    setfield!(S, :dm, dm)
    setfield!(S, :src, ssrc * "," * auth)

    push!(MT, S)
  end

  # ==========================================================================
  # Choose a focal mechanism to retain; then determine mag_id and loc_id
  mag_id = ""
  loc_id = ""
  if length(MT) > 0
    # Store moment tensor with lowest M_err
    if isempty(preferredFocalMechanismID)
      sort!(MT, by=x->sum(abs.(x.dm)))
      R = getindex(MT, 1)
    else
      R = getindex(MT, findfirst([occursin(getfield(m, :id), preferredFocalMechanismID) for m in MT]))
    end

    # Set ID
    if isempty(preferredMagnitudeID)
      mag_id = get(getfield(R, :misc), "derivedOriginID", "")
    else
      mag_id = preferredMagnitudeID
    end

    if isempty(preferredOriginID)
      loc_id = mag_id
    else
      loc_id = preferredOriginID
    end
  else
    R = SeisSrc()
  end

  # ==========================================================================
  # Magnitude
  H = SeisHdr()
  setfield!(R, :eid, identity(getfield(H, :id)))

  n = 0
  oid = ""
  pid = ""
  auth = ""
  m = -5.0f0
  msc = ""
  nst = 0
  gap = 0.0
  while n < length(mags)
    n = n+1
    mag = getindex(mags, n)
    oid = ""
    pid = ""
    auth = ""
    m = -5.0f0
    msc = ""
    nst = 0
    gap = 0.0

    # src
    originID = get_elements_by_tagname(mag, "originID")
    pid = attribute(mag, "publicID")
    oid = isempty(originID) ? "" : content(first(originID))

    # msc
    mtype = get_elements_by_tagname(mag, "type")
    msc = isempty(mtype) ? "" : content(first(mtype))

    if occursin(oid, mag_id) || n == 1 || startswith(lowercase(msc), "mw")
      for child in child_elements(mag)
        cname = name(child)
        if cname == "mag"
          m = parse(Float32, content(first(get_elements_by_tagname(child, "value"))))
        elseif cname == "stationCount"
          nst = parse(Int64, content(child))
        elseif cname == "azimuthalGap"
          gap = parse(Float64, content(child))
        elseif cname == "creationInfo"
          for grandchild in child_elements(child)
            if name(grandchild) ==  "author"
              auth = content(grandchild)
            end
          end
        end
      end
    end
  end
  MAG = EQMag(m, msc, nst, gap, pid * "," * oid * "," * auth)

  # ==========================================================================
  # Location
  n = 0
  nst = 0
  ot = "1970-01-01T00:00:00"
  gap = 0.0
  auth = ""
  ltyp = ""
  loc_src = ""
  locflags = Array{Char, 1}(undef,8)
  fill!(locflags, '0')
  loc = zeros(Float64, 12)
  while n < length(origs)
    n = n+1
    orig = getindex(origs, n)

    # _______________________________________________________
    # Only parse locations corresponding to a desirable ID
    if occursin(attribute(orig, "publicID"), loc_id) || (n == 1)
      loc_src = attribute(orig, "publicID")

      # Reset temp variables
      nst = 0
      gap = 0.0
      auth = ""
      ltyp = ""
      ot = "1970-01-01T00:00:00"
      fill!(locflags, '0')
      fill!(loc, zero(Float64))

      # Try to set location first
      j = 0
      for str in ("latitude", "longitude", "depth")
        j = j + 1
        (loc[j], dloc) = get_RealQuantity(orig, str)
        if j == 1
          loc[5] = dloc
        elseif j == 2
          loc[4] = dloc
        elseif j == 3
          setindex!(loc, getindex(loc, 3)*0.001, 3)
          loc[6] = dloc
        end
      end

      # Now loop
      for child in child_elements(orig)
        cname = name(child)

        #= Removed 2019-11-01.
          No documentation of originUncertainty is known to exist;
          can't ascertain intended meaning/use of originUncertainty;
          can't tell if observatories use it uniformly

        if cname == "originUncertainty"
          dh_min = zero(Float64)
          dh_max = zero(Float64)
          for grandchild in child_elements(child)
            gcname = name(grandchild)
            if gcname == "horizontalUncertainty"
              loc[4] = 500.0 * parse(Float64, content(grandchild))
            elseif gcname == "minHorizontalUncertainty"
              dh_min = parse(Float64, content(grandchild))
            elseif gcname == "maxHorizontalUncertainty"
              dh_max = parse(Float64, content(grandchild))
            end
          end
          if (dh_min != zero(Float64)) && (dh_max != zero(Float64)) && (loc[4] == zero(Float64))
            loc[4] = 500.0 * (dh_min + dh_max)
          end
        =#

        if cname == "type"
          ltyp_tmp = content(child)
          if ltyp_tmp != ""
            ltyp = ltyp_tmp
          end

        elseif cname == "time"
          for grandchild in child_elements(child)
            gcname = name(grandchild)
            if gcname == "value"
              ot = content(grandchild)
            elseif gcname == "uncertainty"
              loc[7] = parse(Float64, content(grandchild))
            end
          end

        elseif cname == "quality"
          for grandchild in child_elements(child)
            gcname = name(grandchild)
            if gcname == "standardError"
              loc[8] = parse(Float64, content(grandchild))
            elseif gcname == "azimuthalGap"
              loc[10] = parse(Float64, content(grandchild))
            elseif gcname == "minimumDistance"
              loc[11] = parse(Float64, content(grandchild))
            elseif gcname == "maximumDistance"
              loc[12] = parse(Float64, content(grandchild))
            elseif gcname == "associatedStationCount"
              nst = parse(Int64, content(grandchild))
            end
          end

        elseif cname == "epicenterFixed"
          locflags[1] = content(child)[1]
          locflags[2] = locflags[1]

        elseif cname == "depthType"
          if content(child) == "operator assigned"
            locflags[3] = '1'
          end

        elseif cname == "timeFixed"
          locflags[4] = content(child)[1]

        elseif cname == "creationInfo"
          for grandchild in child_elements(child)
            if name(grandchild) ==  "author"
              auth = content(grandchild)
            end
          end
        elseif (cname in ("latitude", "longitude", "depth")) == false
          H.misc["xloc_" * cname] = string(child)
        end
      end
      # _______________________________________________________

    end
  end
  LOC = EQLoc(loc..., nst, parse(UInt8, join(locflags), base=2), "", ltyp, "", loc_src * "," * auth )

  setfield!(H, :id, String(evt_id))
  setfield!(H, :loc, LOC)
  setfield!(H, :ot, DateTime(replace(ot, r"[A-S,U-Z,a-z]" => "")[1:min(end,23)]))
  setfield!(H, :mag, MAG)
  setfield!(H, :typ, eqtype)
  setfield!(H, :src, evt_src)
  setfield!(R, :eid, String(evt_id))

  # Post-process: ensure these are empty if not initialized
  if R.mt == zeros(Float64,6)
    R.mt = Float64[]
  end

  if R.dm == Inf64.*ones(Float64,6)
    R.dm = Float64[]
  end

  if R.pax == zeros(Float64, 3, 3)
    R.pax = Array{Float64, 2}(undef, 0, 0)
  end

  if R.planes == zeros(Float64, 3, 2)
    R.planes = Array{Float64, 2}(undef, 0, 0)
  end

  if R.src == ","
    R.src = ""
  end
  return H, R
end

function event_xml!(EvCat::Array{SeisHdr,1}, EvSrc::Array{SeisSrc, 1}, xdoc::XMLDocument)
  qxml  = first(child_elements(root(xdoc)))
  elts  = child_elements(qxml)
  for elt in elts
    if name(elt) == "event"
      H, R = parse_qml(elt)
      push!(EvCat, H)
      push!(EvSrc, R)

    end
  end
  return nothing
end

"""
    EvCat, EvSrc = read_qml(fpat::String)

Read QuakeML files matching string pattern `fpat`. Returns an array of `SeisHdr`
objects as `EvCat` and an array of `SeisSrc` objects as `EvSrc`, such that
`EvCat[i]` and `EvSrc[i]` describe the preferred location (origin) and
preferred event source (focal mechanism or moment tensor) of event `i`.

"""
function read_qml(fpat::String)
  files = safe_isfile(fpat) ? [fpat] : ls(fpat)
  EvCat = Array{SeisHdr,1}()
  EvSrc = Array{SeisSrc,1}()
  for file in files
    xdoc  = parse_file(file)
    event_xml!(EvCat, EvSrc, xdoc)
    free(xdoc)
  end
  return EvCat, EvSrc
end


function is_qml(k::String, s::String)
  (startswith(s, "<") && endswith(s, ">")) || return false
  i1 = first(findnext("<", s,1))
  j1 = last(findnext(">", s,1))
  s1 = s[nextind(s, i1):prevind(s, j1)]
  (split(k, "_")[2] == s1) || return false
  i2 = first(findlast("<", s))
  j2 = last(findlast(">", s))
  s2 = s[nextind(s, i2):prevind(s, j2)]
  ("/" * s1) == s2 || return false
  return true
end

function new_qml!(io::IO)
  write(io, "<?xml version=\"1.0\" encoding=\"UTF-8\"?>
  <quakeml xmlns=\"http://quakeml.org/xmlns/quakeml/1.2\">\n  <eventParameters publicID=\"smi:SeisIO.jl\">\n    <creationInfo>\n      <agencyID>SeisIO</agencyID>\n      <creationTime>")
  print(io, now())
  write(io, "</creationTime>\n    </creationInfo>\n")
  return nothing
end

function write_misc(io::IO, D::Dict{String,Any}, pref::String, p::Int64)
  for k in keys(D)
    if startswith(k, pref)
      xv = D[k]
      if is_qml(k, xv)
        write(io, " "^2p)
        write(io, xv)
        write(io, "\n")
      end
    end
  end
  return nothing
end

function write_real(io::IO, str::String, x::Union{DateTime,AbstractFloat}, p::Int64)
  write(io, " "^2p, "<")
  write(io, str)
  write(io, ">\n", " "^(2p+2), "<value>")
  print(io, x)
  write(io, "</value>\n", " "^2p, "</")
  write(io, str)
  write(io, ">\n")
  return nothing
end

function write_real(io::IO, str::String, x::Union{DateTime,AbstractFloat}, dx::AbstractFloat, p::Int64)
  write(io, " "^2p, "<")
  write(io, str)
  write(io, ">\n", " "^(2p+2), "<value>")
  print(io, x)
  write(io, "</value>\n", " "^(2p+2), "<uncertainty>")
  print(io, dx)
  write(io, "</uncertainty>\n", " "^2p, "</")
  write(io, str)
  write(io, ">\n")
  return nothing
end

function write_pax(io::IO, pax::Array{Float64,2})
  str = ("t", "p", "n")
  nP = size(pax, 2)
  write(io, "        <principalAxes>\n")
  for i in 1:nP
    write(io, "          <", str[i], "Axis>\n")
    write(io, "            <azimuth>\n              <value>")
    print(io, pax[1,i])
    write(io, "</value>\n            </azimuth>\n")
    write(io, "            <plunge>\n              <value>")
    print(io, pax[2,i])
    write(io, "</value>\n            </plunge>\n")
    write(io, "            <length>\n              <value>")
    print(io, pax[3,i])
    write(io, "</value>\n            </length>\n")
    write(io, "          </", str[i], "Axis>\n")
  end
  write(io, "        </principalAxes>\n")
  return nothing
end

function write_qml!(io::IO, HDR::Array{SeisHdr,1}, SRC::Array{SeisSrc,1}, v::Int64)
  Ri = zeros(Int64, length(HDR))
  R_id = Array{String,1}(undef, length(SRC))
  for i in 1:length(SRC)
    R_id[i] = getfield(SRC[i], :eid)
  end

  for i in 1:length(HDR)
    id = getfield(HDR[i], :id)
    for j in 1:length(R_id)
      if id == R_id[j]
        Ri[i] = j
        break
      end
    end
  end

  for i in 1:length(HDR)
    H = HDR[i]
    (v > 0) && println("Writing event ", H.id)

    write(io, "<event publicID=\"")
    print(io, H.src)
    write(io, "\">\n")
    if isempty(H.loc)
      (v > 0) && println("  Skipped location (H.loc empty)")
    else
      loc_orig, loc_auth, xx = split_id(H.loc.src, c=",")
      write(io, "      <preferredOriginID>")
      write(io, H.id)
      write(io, "</preferredOriginID>\n      <type>")
      write(io, H.typ)
      write(io, "</type>\n")

      # ---------------------------------------------------
      # Origin
      write(io, "      <origin publicID=\"", loc_orig, "\">\n")
      if H.loc.dt > 0.0
        write_real(io, "time", H.ot, H.loc.dt, 4)
      else
        write_real(io, "time", H.ot, 4)
      end
      L = H.loc

      # lat, lon, dep
      if L.dy == 0.0
        write_real(io, "latitude", L.lat, 4)
      else
        write_real(io, "latitude", L.lat, L.dy, 4)
      end
      if L.dx == 0.0
        write_real(io, "longitude", L.lon, 4)
      else
        write_real(io, "longitude", L.lon, L.dx, 4)
      end
      if L.dz == 0.0
        write_real(io, "depth", L.dep*1000.0, 4)
      else
        write_real(io, "depth", L.dep*1000.0, L.dz, 4)
      end

      # flags
      flags = falses(4)
      for n = 1:4
        flags[n] = >>(<<(H.loc.flags, n-1),7)
      end
      if flags[3]
        write(io, "        <depthType>operator assigned</depthType>\n")
      end
      if flags[4]
        write(io, "        <timeFixed>1</timeFixed>\n")
      end
      if flags[1] || flags[2]
        write(io, "        <epicenterFixed>1</epicenterFixed>\n")
      end

      # Location quality
      do_qual = false
      for f in loc_qual_fields
        if getfield(L, f) != 0.0
          do_qual = true
          break
        end
      end
      if do_qual || (L.nst > 0)
        write(io, "        <quality>\n")

        if L.nst > 0
          write(io, "          <associatedStationCount>")
          print(io, L.nst)
          write(io, "</associatedStationCount>\n")
        end

        for (i,f) in enumerate(loc_qual_fields)
          j = getfield(L, f)
          if j != 0.0
            write(io, "          <")
            write(io, loc_qual_names[i])
            write(io, ">")
            print(io, j)
            write(io, "</")
            write(io, loc_qual_names[i])
            write(io, ">\n")
          end
        end
        write(io, "        </quality>\n")
      end

      # Author
      if !isempty(loc_auth)
        write(io, "        <creationInfo>\n          <author>")
        print(io, loc_auth)
        write(io, "</author>\n        </creationInfo>\n")
      end

      # other location properties
      write_misc(io, H.misc, "xloc_", 4)

      # done Origin
      write(io, "      </origin>\n")
    end

    # ---------------------------------------------------
    # Focal Mechanism
    if Ri[i] == 0
      (v > 0) && println("  Skipped focal mechanism (no R.eid matches)\n  Skipped moment tensor (fields empty)")
    else
      j = Ri[i]
      R = SRC[j]

      foc_orig, foc_auth, xx = split_id(R.src, c=",")
      write(io, "      <focalMechanism publicID=\"")
      write(io, foc_orig)
      write(io, "\">\n")

      # Nodal planes
      if !isempty(R.planes)
        write(io, "        <nodalPlanes>\n")
        nP = size(R.planes, 2)
        for i in 1:nP
          write(io, "          <nodalPlane")
          print(io, i)
          write(io, ">\n")
          write(io, "            <strike>\n              <value>")
          print(io, R.planes[1,i])
          write(io, "</value>\n            </strike>\n")
          write(io, "            <dip>\n              <value>")
          print(io, R.planes[2,i])
          write(io, "</value>\n            </dip>\n")
          write(io, "            <rake>\n              <value>")
          print(io, R.planes[3,i])
          write(io, "</value>\n            </rake>\n")
          write(io, "          </nodalPlane")
          print(io, i)
          write(io, ">\n")
        end
        write(io, "        </nodalPlanes>\n")
      end

      # Principal axes
      if !isempty(R.pax)
        write_pax(io, R.pax)
      end

      # Azimuthal gap
      if R.gap != 0.0
        write(io, "        <azimuthalGap>")
        print(io, R.gap)
        write(io, "</azimuthalGap>\n")
      end

      # methodID
      if haskey(R.misc, "methodID")
        write(io, "        <methodID>")
        write(io, get(R.misc, "methodID", ""))
        write(io, "</methodID>\n")
      end

      # Author
      if !isempty(foc_auth)
        write(io, "        <creationInfo>\n            <author>")
        write(io, foc_auth)
        write(io, "</author>\n          </creationInfo>\n")
      end

      # Moment Tensor
      if (isempty(R.mt) && (R.m0 == 0.0) && isempty(R.st))
        (v > 0) && println("  Skipped moment tensor (fields empty)")
      else
        write(io, "        <momentTensor publicID=\"")
        mt_id = haskey(R.misc, "mt_id") ? R.misc["mt_id"] : "smi:SeisIO/moment_tensor;fmid=" * R.id
        write(io, mt_id)
        write(io, "\">\n")

        if R.m0 != 0.0
          write_real(io, "scalarMoment", R.m0, 5)
        end

        if isempty(R.mt) == false
          write(io, "          <tensor>\n")
          mt_strings = ("Mrr", "Mtt", "Mpp", "Mrt", "Mrp", "Mtp")
          for i = 1:length(R.mt)
            write_real(io, mt_strings[i], R.mt[i], R.dm[i], 6)
          end
          write(io, "          </tensor>\n")
          write_misc(io, R.misc, "xmt_", 5)
        end

        if !isempty(R.st)
          write(io, "          <sourceTimeFunction>\n")
          write(io, "            <type>")
          write(io, R.st.desc)
          write(io, "</type>\n")
          write(io, "            <duration>")
          print(io, R.st.dur)
          write(io, "</duration>\n")
          write(io, "            <riseTime>")
          print(io, R.st.rise)
          write(io, "</riseTime>\n")
          write(io, "            <decayTime>")
          print(io, R.st.decay)
          write(io, "</decayTime>\n")
          write(io, "          </sourceTimeFunction>\n")
        end
        write(io, "        </momentTensor>\n")
      end

      write(io, "      </focalMechanism>\n")
    end

    # ---------------------------------------------------
    # Magnitude
    if isempty(H.mag)
      (v > 0) && println("  Skipped magnitude (H.mag empty)")
    else
      mag_pid, mag_orig, mag_auth, xx = split_id(H.mag.src, c=",")
      write(io, "      <magnitude publicID=\"")
      write(io, mag_pid)
      write(io, "\">\n")
      write_real(io, "mag", H.mag.val, 4)
      write(io, "        <type>", H.mag.scale, "</type>\n")
      isempty(mag_orig) || write(io, "        <originID>", mag_orig, "</originID>\n")

      if !isempty(mag_auth)
        write(io, "        <creationInfo>\n          <author>", mag_auth, "</author>\n        </creationInfo>\n")
      end

      if H.mag.gap != 0.0
        write(io, "        <azimuthalGap>")
        print(io, H.mag.gap)
        write(io, "</azimuthalGap>\n")
      end

      if H.mag.nst > 0
        write(io, "        <stationCount>")
        print(io, H.mag.nst)
        write(io, "</stationCount>\n")
      end

      write(io, "      </magnitude>\n")
    end
    write(io, "    </event>\n")
  end
  write(io, "</eventParameters>\n</quakeml>\n")
  return nothing
end

@doc """
    write_qml(fname, SHDR::SeisHdr; v::Int64=0)
    write_qml(fname, SHDR::Array{SeisHdr,1}; v::Int64=0)

Write QML to file `fname` from `SHDR`.

If `fname` exists, and is QuakeML, SeisIO appends the existing XML. If the
file exists, but is NOT QuakeML, an error is thrown; the file isn't overwritten.

    write_qml(fname, SHDR::SeisHdr, SSRC::SeisSrc; v::Int64=0)
    write_qml(fname, SHDR::Array{SeisHdr,1}, SSRC::Array{SeisSrc,1}; v::Int64=0)

Write QML to file `fname` from `SHDR` and `SSRC`.

!!! warning

    To write data from `R ∈ SSRC`, it must be true that `R.eid == H.id` for some `H ∈ SHDR`.
""" write_qml
function write_qml(fname::String, HDR::Array{SeisHdr,1}, SRC::Array{SeisSrc,1}; v::Int64=0)
  H0 = SeisHdr[]
  R0 = SeisSrc[]

  if safe_isfile(fname)
    io = open(fname, "a+")

    # test whether file can be appended
    seekend(io)
    skip(io, -30)
    test_str = String(read(io))
    if test_str == "</eventParameters>\n</quakeml>\n"

      # behavior for files that are QuakeXML as produced by SeisIO
      skip(io, -30)
    else
      try

        # file exists and is readable QuakeXML but not produced by SeisIO
        seekstart(io)
        fstart = String(read(io, 5))
        if fstart == "<?xml"
          close(io)
          append!(H0, HDR)
          append!(R0, SRC)
          (H1, R1) = read_qml(fname)
          @assert (isempty(H1) == false)
          @assert (isempty(R1) == false)
          append!(H0, H1)
          append!(R0, R1)
        else
          error("incompatible file type!")
        end
      catch err

        # file exists but isn't QuakeXML
        @warn(string(fname, " isn't valid QuakeXML; can't append, exit with error!"))
        rethrow(err)
      end

      io = open(fname, "w")
      new_qml!(io)
    end
  else

    # new file
    io = open(fname, "w")
    new_qml!(io)
  end

  if isempty(H0) && isempty(R0)
    write_qml!(io, HDR, SRC, v)
  else
    write_qml!(io, H0, R0, v)
  end
  close(io)
  return nothing
end
write_qml(fname::String, H::SeisHdr, R::SeisSrc; v::Int64=0) = write_qml(fname, [H], [R], v=v)
write_qml(fname::String, HDR::Array{SeisHdr,1}; v::Int64=0) = write_qml(fname, HDR, SeisSrc[], v=v)
write_qml(fname::String, H::SeisHdr; v::Int64=0) = write_qml(fname, [H], SeisSrc[], v=v)
