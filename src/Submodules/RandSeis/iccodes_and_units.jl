rand_seis_unit() = rand() > 0.5 ? "m" : "m/s"
rand_seis_cc() = rand(rand() > 0.2 ? zne : nvc)

const cDict = Dict{Char, Function}(
  'H' => i->rand_seis_cc(),
  'L' => i->rand_seis_cc(),
  'N' => i->rand_seis_cc(),
  'A' => i->rand() > 0.5 ? 'N' : 'E',
  'B' => i->'_',
  'D' => i->rand(oidfhu),
  'F' => i->rand(zne),
  'G' => i->rand(nvc),
  'I' => i->rand(oid),
  'J' => i->rand(nvc),
  'K' => i->rand(oid),
  'M' => i->rand(nvc),
  'O' => i->'_',
  'P' => i->rand(zne),
  'Q' => i->'_',
  'R' => i->'_',
  'S' => i->rand(zne),
  'T' => i->'Z',
  'U' => i->'_',
  'V' => i->'_',
  'W' => i->rand() > 0.5 ? 'S' : 'D',
  'Z' => i->rand(icfo),
  )

const uDict = Dict{Char, Function}(
    'H' => i->rand_seis_unit(),
    'N' => i->"m/s2",
    'L' => i->rand_seis_unit(),
    'A' => i->"rad",
    'B' => i->"m",
    'D' => i->"Pa",
    'F' => i->"T",
    'G' => i->"m/s2",
    'I' => i->"%",
    'J' => i->rand(junits),
    'K' => i->rand() > 0.5 ? "Cel" : "K",
    'M' => i->"m",
    'O' => i->"m/s",
    'P' => i->rand_seis_unit(),
    'Q' => i->"V",
    'R' => i->rand_seis_unit(),
    'S' => i->"m/m",
    'T' => i->"m",
    'U' => i->"%{cloud_cover}",
    'V' => i->"m3/m3",
    'W' => i->i=='S' ? "m/s" : "{direction_vector}",
    'Z' => i->rand_seis_unit(),
  )

  """
     (cha, u) = iccodes_and_units(b::Char, s::Bool)

Using band code `b`, generate quasi-sane random instrument code `i` and channel code `c`, returning channel string `cha` = `b`*`i`*`c` and unit string `u`. If `s=true`, use only seismic intrument codes.
"""
function iccodes_and_units(b::Char, s::Bool)
  i = rand(s ? hln : iclist)
  c = cDict[i](b)
  u = uDict[i](c)
  return string(b, i, c), u
end
