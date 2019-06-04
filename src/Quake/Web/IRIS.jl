export get_pha!

"""
    T = get_pha(Δ::Float64, z::Float64)

Command-line interface to IRIS online travel time calculator, which calls TauP [1-2].
Returns a matrix of strings.

Specify Δ in decimal degrees, z in km treating down as +.

Standard keywords: pha, to, v

Additional keywords:
* model: velocity model ("iasp91")

### References
[1] TauP manual: http://www.seis.sc.edu/downloads/TauP/taup.pdf
[2] Crotwell, H. P., Owens, T. J., & Ritsema, J. (1999). The TauP Toolkit:
Flexible seismic travel-time and ray-path utilities, SRL 70(2), 154-160.
"""
function get_pha!(Ev::SeisEvent;
                  pha::String   = KW.pha,
                  model::String = "iasp91",
                  to::Int64     = KW.to,
                  v::Int64      = KW.v
                  )

  # Check that distaz has been done
  TD = getfield(Ev, :data)
  N = getfield(TD, :n)
  z = zeros(Float64, N)
  if (TD.az == z) && (TD.baz == z) && (TD.dist == z)
    v > 0 && println(stdout, "az, baz, and dist are unset; calling distaz!...")
    distaz!(Ev)
  end

  # Generate URL and do web query
  src_dep = getfield(getfield(getfield(Ev, :hdr), :loc), :dep)
  if isempty(pha) || pha == "all"
    pq = "&phases=ttall"
  else
    pq = string("&phases=", pha)
  end
  url_tail = string("&evdepth=", src_dep, pq, "&model=", model, "&mintimeonly=true&noheader=true")

  # Loop begins
  dist = getfield(TD, :dist)
  PC = getfield(TD, :pha)
  for i = 1:N
    Δ = getindex(dist, i)
    pcat = getindex(PC, i)

    url = string("http://service.iris.edu/irisws/traveltime/1/query?", "distdeg=", Δ, url_tail)
    v > 1 && println(stdout, "url = ", url)

    req_info_str = string("\nIRIS travel time request:\nΔ = ", Δ, "\nDepth = ", z, "\nPhases = ", pq, "\nmodel = ", model)
    (R, parsable) = get_HTTP_req(url, req_info_str, to)

    # Parse results
    if parsable
      req = String(take!(copy(IOBuffer(R))))
      pdat = split(req, '\n')
      deleteat!(pdat, findall(isempty, pdat))   # can have trailing blank line
      npha = length(pdat)
      for j = 1:npha
        pha = split(pdat[j], keepempty=false)
        pcat[pha[10]] = SeisPha(0.0,                              # a
                                parse(Float64, pha[8]),           # d
                                parse(Float64, pha[7]),           # ia
                                0.0,                              # res
                                parse(Float64, pha[5]),           # rp
                                parse(Float64, pha[6]),           # ta
                                parse(Float64, pha[4]),           # tt
                                0.0,                              # unc
                                ' ',                              # pol
                                ' ',                              # qual
                                )
      end
    end
  end
  return nothing
end
# "Model: iasp91"
# "Distance   Depth   Phase        Travel    Ray Param  Takeoff  Incident  Purist    Purist    "
# "  (deg)     (km)   Name         Time (s)  p (s/deg)   (deg)    (deg)   Distance   Name      "
# "--------------------------------------------------------------------------------------------"
# "   66.83    19.7   P             650.37     6.375     19.49    19.42    66.83   = P"
# "   66.83    19.7   pP            656.77     6.385    160.48    19.45    66.83   = pP"
# "   66.83    19.7   sP            659.32     6.383    168.84    19.45    66.83   = sP"
# "   66.83    19.7   PcP           678.82     4.167     12.59    12.55    66.83   = PcP"
# "   66.83    19.7   PP            797.49     8.699     27.08    26.98    66.83   = PP"
# "   66.83    19.7   PKiKP        1038.70     1.352      4.06     4.04    66.83   = PKiKP"
# "   66.83    19.7   pPKiKP       1045.47     1.352    175.94     4.04    66.83   = pPKiKP"
# "   66.83    19.7   sPKiKP       1047.95     1.352    177.65     4.04    66.83   = sPKiKP"
# "   66.83    19.7   S            1182.56    12.085     21.49    21.42    66.83   = S"
# "   66.83    19.7   pS           1190.65    12.109    140.68    21.46    66.83   = pS"
# "   66.83    19.7   sS           1193.48    12.101    158.48    21.45    66.83   = sS"
# "   66.83    19.7   SP           1201.90    13.645     24.43    45.38    66.83   = SP"
# "   66.83    19.7   PS           1204.86    13.644     45.55    24.35    66.83   = PS"
# "   66.83    19.7   SKS          1246.03     7.572     13.27    13.23    66.83   = SKS"
# "   66.83    19.7   SKKS         1246.05     7.585     13.29    13.25    66.83   = SKKS"
# "   66.83    19.7   ScS          1246.40     7.761     13.61    13.56    66.83   = ScS"
# "   66.83    19.7   SKiKP        1250.70     1.408      2.45     4.21    66.83   = SKiKP"
# "   66.83    19.7   pSKS         1254.86     7.573    156.66    13.23    66.83   = pSKS"
# "   66.83    19.7   sSKS         1257.44     7.573    166.73    13.23    66.83   = sSKS"
# "   66.83    19.7   SS           1441.81    15.478     27.98    27.88    66.83   = SS"
# "   66.83    19.7   PKIKKIKP     1860.33     1.411      4.23     4.22   293.17   = PKIKKIKP"
# "   66.83    19.7   SKIKKIKP     2072.34     1.352      2.35     4.05   293.17   = SKIKKIKP"
# "   66.83    19.7   PKIKKIKS     2074.81     1.352      4.06     2.34   293.17   = PKIKKIKS"
# "   66.83    19.7   SKIKKIKS     2286.62     1.297      2.25     2.25   293.17   = SKIKKIKS"
# "   66.83    19.7   PKIKPPKIKP   2359.03     1.666      5.00     4.98   293.17   = PKIKPPKIKP"
# "   66.83    19.7   PKPPKP       2361.68     2.976      8.96     8.93   293.17   = PKPPKP"
# "   66.83    19.7   PKPPKP       2364.24     3.928     11.86    11.82   293.17   = PKPPKP"
# "   66.83    19.7   SKIKSSKIKS   3216.94     1.426      2.48     2.47   293.17   = SKIKSSKIKS"
