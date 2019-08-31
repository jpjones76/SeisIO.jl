printstyled("  findid\n", color=:light_green)
id = "UW.TDH..EHZ"
IDs = ["UW.WWVB..TIM","UW.TCG..TIM","UW.TDH..EHZ","UW.VLM..EHZ"]
@test findid(id, IDs) == findid(codeunits(id), IDs) == findfirst(IDs.==id) == 3
@test findid("aslkasnglknsgf", IDs) == 0
