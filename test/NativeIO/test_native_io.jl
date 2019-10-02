# save to disk/read from disk
savfile1  = "test.seis"
savfile2  = "test.hdr"
savfile3  = "test.evt"
legf_050  = path * "/SampleFiles/SEIS/2011.314.7D.J34A..HH1.seis"
legf_052  = path * "/SampleFiles/SEIS/seisio_testfile_v0.52.seis"
uw_file   = path * "/SampleFiles/UW/02062915175o"

# Changing this test to guarantee at least one campaign-style measurement ... and test splat notation ... and something with no notes
printstyled("  SeisData\n", color=:light_green)
S = breaking_seis()
wseis(savfile1, S)
R = rseis(savfile1)[1]
@test(R==S)
S.notes[2][1] = string(String(Char.(0x00:0x7e)), String(Char.(0x80:0xff)))
wseis(savfile1, S)
R = rseis(savfile1)[1]
@test(R!==S)

printstyled("  SeisHdr\n", color=:light_green)
H = randSeisHdr()
wseis(savfile2, H)
H2 = rseis(savfile2)[1]
@test(H==H2)

printstyled("  SeisEvent\n", color=:light_green)
EV = SeisEvent(hdr=H, data=convert(EventTraceData, S))
EV.data.misc[1] = breaking_dict
wseis(savfile3, EV)
R = rseis(savfile3)[1]
@test R == EV

printstyled("  read/write of each type to same file\n", color=:light_green)
Ch = randSeisChannel(s=true)
Ch.x = rand(24)
Ch.t = vcat(Ch.t[1], [24 0])
wseis(savfile3, EV, S, H, Ch)

R = rseis(savfile3)
@test(R[1]==EV)
@test(R[2]==S)
@test(R[3]==H)
@test(R[4]==Ch)
@test(S.misc[1] == R[1].data.misc[1] ==  R[2].misc[1])

# read one file with one record number
printstyled("  read file with integer record number\n", color=:light_green)
R = rseis("test.seis", c=1, v=1)
@test R[1] == S

# read everything
printstyled("  read a multi-record file\n", color=:light_green)
R = rseis("test*", v=1)
@test R[3] == R[5] # Header is read twice, test.evt (file 1) record 3, test.hdr (file 2) record 1
@test R[2] == R[6] # Seis is read twice, test.evt (file 1) record 2, test.seis (file 3) record 1

# read when some files have record 3 but not all
printstyled("  read file list with list of record numbers\n", color=:light_green)
R = rseis("test.*", c = [1,3], v=1)
@test(R[3]==R[2])
@test(R[1].data.misc[1]==R[4].misc[1])

# read nothing as each target file has one record
printstyled("  read nothing due to an intentionally poor choice of record numbers\n", color=:light_green)
R = rseis(["test.seis", "test.h*"], c=[2, 3], v=1)
@test isempty(R)

# read the first record of each file
printstyled("  read first record from each SeisIO file using a wildcard list\n", color=:light_green)
R = rseis("test*", c=1, v=1)
@test R[1] == EV
@test R[2] == H
@test R[3] == S

printstyled("  test that every custom Type can be written and read faithfully\n", color=:light_green)
redirect_stdout(out) do
  A = Array{Any,1}(undef, 0)
  for T in SeisIO.TNames
    println("testing ", T)
    if T == PhaseCat
      push!(A, randPhaseCat())
    elseif T == MultiStageResp
      push!(A, MultiStageResp(6))
    else
      push!(A, getfield(SeisIO, Symbol(T))())
    end
  end
  wseis(savfile1, A...)
  R = rseis(savfile1, v=2)

  for i = 1:length(R)
    @test R[i] == A[i]
  end

  # add an incompatible type; should throw a warning, and another when read back in
  push!(A, rand(Float64,3))
  wseis(savfile1, A...)
  R = rseis(savfile1, v=2)
end

printstyled("  test read/write with data compression\n", color=:light_green)
SeisIO.KW.comp = 0x02
S = randSeisData()
nx = 4
S.t[1] = [1 0; nx 0]
S.x[1] = randn(eltype(S.x[1]), nx)
wseis(savfile1, S)
R = rseis(savfile1, v=2)[1]
@test R == S

SeisIO.KW.comp = 0x01
S = randSeisEvent()
C = SeisChannel()
nx = SeisIO.KW.n_zip*2
C.t = [1 0; nx 0]
C.x = randn(nx)
n = S.data.n
push!(S.data, C)
@test S.data.n == n+1
C = SeisChannel()
nx = 4
C.t = [1 0; nx 0]
C.x = randn(nx)
push!(S.data, C)
wseis(savfile1, S)
R = rseis(savfile1, v=2)[1]
@test R == S

# read_data("seisio", ...)
S1 = read_data(savfile1)
@test convert(SeisData, S.data) == S1
S1 = read_data("seisio", savfile1)
@test convert(SeisData, S.data) == S1
S2 = rseis(savfile3)
S1 = read_data(savfile3)
Tr = S2[1].data
@test Tr.n == S1.n
for i = 1:Tr.n
  if any(isnan, Tr.x[i]) == false
    @test Tr.x[i] == S1.x[i]
  end
end

# Type unit tests with read_data("seisio", ...)
C = randSeisChannel()
wseis(savfile1, C)
S1 = read_data("seisio", savfile1)
@test S1[1] == C
C = convert(EventChannel, randSeisChannel())
wseis(savfile1, C)
S1 = read_data("seisio", savfile1)
@test S1[1] == convert(SeisChannel, C)
S = randSeisData()
wseis(savfile1, S)
S1 = read_data("seisio", savfile1)
@test S1 == S
S = convert(EventTraceData, S)
wseis(savfile1, S)
S1 = read_data("seisio", savfile1)
@test S1 == convert(SeisData, S)
Ev = randSeisEvent()
L = GeoLoc(lat=45.560504, lon=-122.617020, el=51.816, az=180.0, inc=0.0)
wseis(savfile1, L, Ev)
S1 = read_data("seisio", savfile1)
@test S1 == convert(SeisData, Ev.data)

rm(savfile1)
rm(savfile2)
rm(savfile3)

# Legacy file reading ========================================================
# 0.50  all custom types can use write(); rseis, wseis no longer required
#       String arrays and :misc are written in a completely different way
#       Type codes for :misc changed
#       deprecated BigFloat/BigInt support in :misc
#       :n is no longer stored as a UInt32
#       :x compression no longer automatic and changed from Blosc to lz4

set_file_ver(legf_050, 0.4)
@test get_file_ver(legf_050) == 0.4f0
@test_throws ErrorException rseis(legf_050)
@test_throws ErrorException get_file_ver(uw_file)
set_file_ver(legf_050, 0.50)
S = rseis(legf_050)[1]
@test S.n == 3
@test S.id == ["7D.J34A..HH1", "7D.J34A..HH2", "7D.J34A..HHZ"]

# 0.52  2019-09-03    added Types: CoeffResp, MultiStageResp
# 0.51  2019-08-01    added :f0 to PZResp, PZResp64
# (legacy reader is the same for both)

S = rseis(legf_052)[1]
@test S.n == 3
@test S.id == ["IU.COR.00.BH1", "IU.COR.00.BH2", "IU.COR.00.BHZ"]
@test typeof(S.resp[1]) == MultiStageResp
@test typeof(S.resp[1].stage[1]) == PZResp64
@test isapprox(S.resp[1].stage[1].p, [ -0.0173949 + 0.01234im,
                                       -0.0173949 - 0.01234im,
                                       -0.0175489 + 0.0im    ,
                                       -0.0591783 + 0.0im    ,
                                           -39.18 + 49.12im  ,
                                           -39.18 - 49.12im ])
@test isapprox(S.resp[1].gain, [2660.0, 1.67772e6, 1.0])
@test S.resp[1].fac == [0,1,1]
@test S.resp[1].o[1] == "m/s"
@test S.resp[1].i[1] == "v" # note: this was wrong at the time in absolute sense. Should be "V" in UCUM.
