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
  evt_id = split(attribute(evt, "publicID"), r"[;:/=]")[end]
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
    mech      = getindex(mechs, n)
    np        = zeros(Float64, 3, 2)
    pax       = zeros(Float64, 3, 3)
    mt        = zeros(Float64, 6)
    dm        = fill!(zeros(Float64, 6), Inf)

    # generate SeisSrc object
    S = SeisSrc()
    setfield!(S, :id, String(split(attribute(mech, "publicID"), r"[;:/=]")[end]))

    for child in child_elements(mech)
      cname = name(child)

      if cname == "creationInfo"
        for grandchild in child_elements(child)
          if name(grandchild) ==  "author"
            S.misc["author"] = content(grandchild)
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
        for a in child_elements(child)
          if name(a) == "scalarMoment"
            setfield!(S, :m0, parse(Float64, content(a)))
          elseif name(a) == "tensor"
            j = 0
            for k in ("Mrr", "Mtt", "Mpp", "Mrt", "Mrp", "Mtp")
              j = j+1
              (mt[j], dm[j]) = get_RealQuantity(a, k)
            end
          elseif name(a) == "sourceTimeFunction"
            for b in child_elements(a)
              if name(b) == "type"
                S.st.desc = "type = "*content(b)
              elseif name(b) == "duration"
                S.st.dur = parse(Float64, content(b))
              elseif name(b) == "riseTime"
                S.st.rise = parse(Float64, content(b))
              elseif name(b) == "decayTime"
                S.st.decay = parse(Float64, content(b))
              end
            end
          elseif name(a) == "derivedOriginID"
            S.misc["derivedOriginID"] = String(split(content(a), r"[;:/=]")[end])
          else
            S.misc[name(a)] = content(a)
          end
        end
      elseif cname == "methodID"
        S.misc["methodID"] = String(split(content(child), r"[;:/=]")[end])
      else
        S.misc[cname] = content(child)
      end

    end
    setfield!(S, :planes, np)
    setfield!(S, :pax, pax)
    setfield!(S, :mt, mt)
    setfield!(S, :dm, dm)

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
  auth = ""
  oid = ""
  m = -5.0f0
  msc = ""
  nst = 0
  gap = 0.0
  while n < length(mags)
    n = n+1
    mag = getindex(mags, n)

    # src
    originID = get_elements_by_tagname(mag, "originID")
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
  MAG = EQMag(m, msc, nst, gap, "originID " * oid * ",author " * auth)

  # ==========================================================================
  # Location
  n = 0
  ot = ""
  gap = 0.0
  auth = ""
  ltyp = ""
  locflags = Array{Char, 1}(undef,8)
  fill!(locflags, '0')
  nst = zero(Int64)
  loc = zeros(Float64, 12)
  while n < length(origs)
    n = n+1
    orig = getindex(origs, n)

    # _______________________________________________________
    # Only parse locations corresponding to a desirable ID
    if occursin(attribute(orig, "publicID"), loc_id) || (n == 1)

      # Try to set location first
      fill!(loc, zero(Float64))
      j = 0
      for str in ("latitude", "longitude", "depth")
        j = j + 1
        (loc[j], loc[j+3]) = get_RealQuantity(orig, str)
        if j == 3
          setindex!(loc, getindex(loc, 3)*0.001, 3)
        end
      end

      # Now loop
      for child in child_elements(orig)
        cname = name(child)

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

        elseif cname == "type"
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
            if gcname == "azimuthalGap"
              loc[8] = parse(Float64, content(grandchild))
            elseif gcname == "standardError"
              loc[9] = parse(Float64, content(grandchild))
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
          H.misc[cname] = content(child)
        end
      end
      # _______________________________________________________

    end
  end
  LOC = EQLoc(loc..., nst, parse(UInt8, join(locflags), base=2), "", ltyp, "", auth)

  setfield!(H, :id, String(evt_id))
  setfield!(H, :loc, LOC)
  setfield!(H, :ot, DateTime(replace(ot, r"[A-S,U-Z,a-z]" => "")[1:min(end,23)]))
  setfield!(H, :mag, MAG)
  setfield!(H, :typ, eqtype)

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
  free(xdoc)
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
  end
  return EvCat, EvSrc
end


# file = "../internal_tests/2011-tohoku-oki.xml"
# H = qmltohdr(file)[1]
