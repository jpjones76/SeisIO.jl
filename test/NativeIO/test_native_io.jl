# save to disk/read from disk
savfile1 = "test.seis"
savfile2 = "test.hdr"
savfile3 = "test.evt"

# test each allowed value type in :misc dictionaries
# printstyled("    ...accurate r/w of Types allowed as :misc vals...\n", color=:light_green)
D = Dict{String,Any}()
D["0"] = 'c'
D["1"] = randstring(rand(51:100))
D["16"] = rand(UInt8)
D["17"] = rand(UInt16)
D["18"] = rand(UInt32)
D["19"] = rand(UInt64)
D["20"] = rand(UInt128)
D["32"] = rand(Int8)
D["33"] = rand(Int16)
D["34"] = rand(Int32)
D["35"] = rand(Int64)
D["36"] = rand(Int128)
D["48"] = rand(Float16)
D["49"] = rand(Float32)
D["50"] = rand(Float64)
D["80"] = rand(Complex{UInt8})
D["81"] = rand(Complex{UInt16})
D["82"] = rand(Complex{UInt32})
D["83"] = rand(Complex{UInt64})
D["84"] = rand(Complex{UInt128})
D["96"] = rand(Complex{Int8})
D["97"] = rand(Complex{Int16})
D["98"] = rand(Complex{Int32})
D["99"] = rand(Complex{Int64})
D["100"] = rand(Complex{Int128})
D["112"] = rand(Complex{Float16})
D["113"] = rand(Complex{Float32})
D["114"] = rand(Complex{Float64})
D["128"] = collect(rand(Char, rand(4:24)))
D["129"] = collect(Main.Base.Iterators.repeated(randstring(rand(4:24)), rand(4:24)))
D["144"] = collect(rand(UInt8, rand(4:24)))
D["145"] = collect(rand(UInt16, rand(4:24)))
D["146"] = collect(rand(UInt32, rand(4:24)))
D["147"] = collect(rand(UInt64, rand(4:24)))
D["148"] = collect(rand(UInt128, rand(4:24)))
D["160"] = collect(rand(Int8, rand(4:24)))
D["161"] = collect(rand(Int16, rand(4:24)))
D["162"] = collect(rand(Int32, rand(4:24)))
D["163"] = collect(rand(Int64, rand(4:24)))
D["164"] = collect(rand(Int128, rand(4:24)))
D["176"] = collect(rand(Float16, rand(4:24)))
D["177"] = collect(rand(Float32, rand(4:24)))
D["178"] = collect(rand(Float64, rand(4:24)))
D["208"] = collect(rand(Complex{UInt8}, rand(4:24)))
D["209"] = collect(rand(Complex{UInt16}, rand(4:24)))
D["210"] = collect(rand(Complex{UInt32}, rand(4:24)))
D["211"] = collect(rand(Complex{UInt64}, rand(4:24)))
D["212"] = collect(rand(Complex{UInt128}, rand(4:24)))
D["224"] = collect(rand(Complex{Int8}, rand(4:24)))
D["225"] = collect(rand(Complex{Int16}, rand(4:24)))
D["226"] = collect(rand(Complex{Int32}, rand(4:24)))
D["227"] = collect(rand(Complex{Int64}, rand(4:24)))
D["228"] = collect(rand(Complex{Int128}, rand(4:24)))
D["240"] = collect(rand(Complex{Float16}, rand(4:24)))
D["241"] = collect(rand(Complex{Float32}, rand(4:24)))
D["242"] = collect(rand(Complex{Float64}, rand(4:24)))

# io = open("crapfile.bin","w")
# SeisIO.write_misc(io, D)
# close(io)
# io = open("crapfile.bin","r")
# DD = SeisIO.read_misc(io)
# close(io)
# [@test(D[k]==DD[k]) for k in sort(collect(keys(D)))]
# rm("crapfile.bin")

# Changing this test to guarantee at least one campaign-style measurement ... and test splat notation ... and something with no notes
S = SeisData(randSeisData(), randSeisEvent().data, randSeisData(2, c=1.0, s=0.0)[2])
printstyled("    SeisData...\n", color=:light_green)
S.misc[1] = D
# S.notes[2] = []
wseis(savfile1, S)
R = rseis(savfile1)
@test(R[1]==S)

printstyled("    SeisHdr...\n", color=:light_green)
H = randSeisHdr()
wseis(savfile2, H)
H2 = rseis(savfile2)[1]
@test(H==H2)

printstyled("    SeisEvent...\n", color=:light_green)
EV = SeisEvent(hdr=H, data=S)
EV.data.misc[1] = D
wseis(savfile3, EV)

printstyled("    ...read/write of each type to same file...\n", color=:light_green)
Ch = randSeisChannel()
wseis(savfile3, EV, S, H, Ch)

R = rseis(savfile3)
@test(R[1]==EV)
@test(R[2]==S)
@test(R[3]==H)
@test(R[4][1]==Ch)
@test(S.misc[1] == R[1].data.misc[1]==R[2].misc[1])

# read one file with one record number
printstyled("    ...read file with integer record number...\n", color=:light_green)
R = rseis("test.seis", c=1, v=1)
@test R[1] == S

# read everything
printstyled("    ...read a multi-record file...\n", color=:light_green)
R = rseis("test*", v=1)
@test R[3] == R[5] # Header is read twice, test.evt (file 1) record 3, test.hdr (file 2) record 1
@test R[2] == R[6] # Seis is read twice, test.evt (file 1) record 2, test.seis (file 3) record 1

# read when some files have record 3 but not all
printstyled("    ...read file list with list of record numbers...\n", color=:light_green)
R = rseis("test.*", c = [1,3], v=1)
@test(R[3]==R[2])
@test(R[1].data.misc[1]==R[4].misc[1])

# read nothing as each target file has one record
printstyled("    ...this should read nothing due to an intentionally poor choice of record numbers...\n", color=:light_green)
R = rseis(["test.seis", "test.h*"], c=[2, 3], v=1)
@test isempty(R)

# read the first record of each file
printstyled("    ...this should read the first record from each SeisIO file using a wildcard list...\n", color=:light_green)
R = rseis("test*", c=1, v=1)
@test R[1] == EV
@test R[2] == H
@test R[3] == S

printstyled("    ...remove SeisIO test files...\n", color=:light_green)
rm(savfile1)
rm(savfile2)
rm(savfile3)
printstyled("    ...done native file IO test.\n", color=:light_green)

# printstyled("Supported file format IO\n", color=:light_green, bold=true)
