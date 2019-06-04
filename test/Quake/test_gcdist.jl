printstyled("  gcdist\n", color=:light_green)
src = [46.8523, -121.7603]
src2 = [48.7767, -121.8144]
rec = [45.5135 -122.6801; 44.0442 -123.0925; 42.3265 -122.8756]

G0 = gcdist(src, rec)                           # vec, arr
G1 = gcdist(src[1], src[2], rec)                # lat, lon, arr
G2 = gcdist(src[1], src[2], rec[1,1], rec[1,2]) # s_lat, s_lon, r_lat, r_lon
G3 = gcdist(vcat(src',src2'), rec[1,:])             # arr, arr
G4 = gcdist(vcat(src',src2'), rec[1,:])             # arr, rec[1,:]

@test G0 == G1
@test G0[1,:] == G1[1,:] == G2[1,:]
@test G3 == G4
