# save to disk/read from disk
savfile1 = "test.seis"
savfile2 = "test.hdr"
savfile3 = "test.evt"

# Changing this test to guarantee at least one campaign-style measurement ... and test splat notation ... and something with no notes
printstyled("  SeisData\n", color=:light_green)
S = breaking_seis()
wseis(savfile1, S)
R = rseis(savfile1)
@test(R[1]==S)
S.notes[2][1] = string(String(Char.(0x00:0x7e)), String(Char.(0x80:0xff)))
wseis(savfile1, S)
R = rseis(savfile1)
@test(R[1]!==S)

printstyled("  SeisHdr\n", color=:light_green)
H = randSeisHdr()
wseis(savfile2, H)
H2 = rseis(savfile2)[1]
@test(H==H2)

printstyled("  SeisEvent\n", color=:light_green)
EV = SeisEvent(hdr=H, data=convert(EventTraceData, S))
EV.data.misc[1] = breaking_dict
wseis(savfile3, EV)

printstyled("  read/write of each type to same file\n", color=:light_green)
Ch = randSeisChannel(s=true)
Ch.x = rand(24)
Ch.t = vcat(Ch.t[1], [24 0])
wseis(savfile3, EV, S, H, Ch)

R = rseis(savfile3)
@test(R[1]==EV)
@test(R[2]==S)
@test(R[3]==H)
@test(R[4][1]==Ch)
@test(S.misc[1] == R[1].data.misc[1] ==   R[2].misc[1])

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

rm(savfile1)
rm(savfile2)
rm(savfile3)

# printstyled("Supported file format IO\n", color=:light_green, bold=true)

# Checking for write errors
@test_throws ErrorException get_separator(String(Char.(Array{UInt8,1}(0x00:0x01:0xff))))
