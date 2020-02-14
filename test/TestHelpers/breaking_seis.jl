function breaking_seis()
  S = SeisData(randSeisData(), randSeisEvent(), randSeisData(2, c=1.0, s=0.0)[2])

  # Test a channel with every possible dict type
  S.misc[1] = breaking_dict

  # Test a channel with no notes
  S.notes[1] = []

  # Need a channel with a very long name to test in show.jl
  S.name[1] = "The quick brown fox jumped over the lazy dog"

  # Need a channel with a non-ASCII filename
  S.name[2] = "Moominpaskanäköinen"
  S.misc[2]["whoo"] = String[]        # ...and an empty String array in :misc
  S.misc[2]["♃♄♅♆♇"] = rand(3,4,5,6)  # ...and a 4d array in :misc

  #= Here we test true, full Unicode support;
    only 0xff can be a separator in S.notes[2] =#
  S.notes[2] = Array{String,1}(undef,6)
  S.notes[2][1] = String(Char.(0x00:0xfe))
  for i = 2:1:6
    uj = randperm(rand(1:n_unicode))
    S.notes[2][i] = join(unicode_chars[uj])
  end

  # Test short data, loc arrays
  S.loc[1] = GenLoc()
  S.loc[2] = GeoLoc()
  S.loc[3] = UTMLoc()
  S.loc[4] = XYLoc()

  # Responses
  S.resp[1] = GenResp()
  S.resp[2] = PZResp()
  S.resp[3] = MultiStageResp(6)
  S.resp[3].stage[1] = CoeffResp()
  S.resp[3].stage[2] = PZResp()
  S.resp[3].gain[1] = 3.5e15
  S.resp[3].fs[1] = 15.0
  S.resp[3].stage[1].b = randn(Float64, 120)
  S.resp[3].i[1] = "{counts}"
  S.resp[3].o[1] = "m/s"

  S.x[4] = rand(Float64,4)
  S.t[4] = vcat(S.t[4][1:1,:], [4 0])

  # Some IDs that I can search for
  S.id[1] = "UW.VLL..EHZ"
  S.id[2] = "UW.VLM..EHZ"
  S.id[3] = "UW.TDH..EHZ"
  return S
end
