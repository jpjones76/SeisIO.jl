using Statistics

Ch = randSeisChannel()
clear_notes!(Ch)
@test length(Ch.notes) == 1

printstyled("  Notes (annotation and logging)\n", color=:light_green)
S = randSeisData(2)
id_str = "XX.STA.00.EHZ"
S.id[1] = id_str

printstyled("    note!\n", color=:light_green)
note!(S, 1, "hi")
@test occursin("hi", S.notes[1][end])

note!(S, "poor SNR")
@test occursin("poor SNR", S.notes[2][end])

note!(S, string(id_str, " SNR OK"))
@test occursin(" SNR OK", S.notes[1][end])

note!(S, id_str, "why is it clipping again")
@test occursin("clipping", S.notes[1][end])

printstyled("    clear_notes!\n", color=:light_green)
clear_notes!(S, 1)
@test length(S.notes[1]) == 1
@test occursin("notes cleared.", S.notes[1][1])

clear_notes!(S)
for i = 1:2
  @test length(S.notes[i]) == 1
  @test occursin("notes cleared.", S.notes[i][1])
end

note!(S, 2, "whee")
clear_notes!(S, id_str)
@test S.notes[1] != S.notes[2]

@test_throws ErrorException clear_notes!(S, "YY.STA.11.BHE")
clear_notes!(S)

Ev = randSeisEvent()
clear_notes!(Ev)
for i = 1:Ev.data.n
    @test length(Ev.data.notes[i]) == 1
    @test occursin("notes cleared.", Ev.data.notes[i][1])
end
@test length(Ev.hdr.notes) == 1
@test occursin("notes cleared.", Ev.hdr.notes[1])

Ngaps = [size(S.t[i],1)-2 for i =1:2]
ungap!(S)
for i = 1:2
  @test ==(size(S.t[i],1), 2)
end

S.gain = rand(Float64,2)
unscale!(S)
for i = 1:2
  @test ==(S.gain[i], 1.0)
end
demean!(S)

printstyled("    accuracy of automatic logging\n", color=:light_green)
for i = 1:2
  c = (Ngaps[i]>0) ? 1 : 0
  @test length(S.notes[i]) == (3+c)
  if c > 0
    @test occursin("ungap!", S.notes[i][2])
  end
  @test occursin("unscale!", S.notes[i][2+c])
  @test occursin("demean!", S.notes[i][3+c])
end
