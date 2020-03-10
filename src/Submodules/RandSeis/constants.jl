const h_crit = Float32(1/sqrt(2))

const fc_vals = Tuple(vcat(Float64[1/120, 1/60],  # STS-2, CMG-3T
                       repeat([1/30], 2),         # CMG-40
                       [0.2],                     # Lennartz LE-3D
                       repeat([1.0], 5),          # ...everything...
                       repeat([2.0], 2),          # passive geophones
                       [4.5]))                    # passive industry geophones
const fs_vals = (0.1, 1.0, 2.0, 5.0, 10.0, 20.0, 25.0, 40.0, 50.0, 60.0, 62.5, 80.0, 100.0)

const irregular_units = ("%",
 "%{cloud_cover}",
 "{direction_vector}",
 "Cel",
 "K",
 "{none}",
 "Pa",
 "T",
 "V",
 "W",
 "m",
 "m/m",
 "m/s",
 "m/s2",
 "m3/m3",
 "rad",
 "rad/s",
 "rad/s2",
 "t{SO_2}")

# Acceptable type codes in :misc
const OK = (      0x00, 0x01,
                  0x10, 0x11, 0x12, 0x13, 0x14,
                  0x20, 0x21, 0x22, 0x23, 0x24,
                  0x30, 0x31, 0x32,
                  0x50, 0x51, 0x52, 0x53, 0x54,
                  0x60, 0x61, 0x62, 0x63, 0x64,
                  0x70, 0x71, 0x72,
                  0x80, 0x81,
                  0x90, 0x91, 0x92, 0x93, 0x94,
                  0xa0, 0xa1, 0xa2, 0xa3, 0xa4,
                  0xb0, 0xb1, 0xb2,
                  0xd0, 0xd1, 0xd2, 0xd3, 0xd4,
                  0xe0, 0xe1, 0xe2, 0xe3, 0xe4,
                  0xf0, 0xf1, 0xf2 )

const evtypes = (       "not_existing",
                        "not_reported",
                        "anthropogenic_event",
                        "collapse",
                        "cavity_collapse",
                        "mine_collapse",
                        "building_collapse",
                        "explosion",
                        "accidental_explosion",
                        "chemical_explosion",
                        "controlled_explosion",
                        "experimental_explosion",
                        "industrial_explosion",
                        "mining_explosion",
                        "quarry_blast",
                        "road_cut",
                        "blasting_levee",
                        "nuclear_explosion",
                        "induced_or_triggered_event",
                        "rock_burst",
                        "reservoir_loading",
                        "fluid_injection",
                        "fluid_extraction",
                        "crash",
                        "plane_crash",
                        "train_crash",
                        "boat_crash",
                        "other_event",
                        "atmospheric_event",
                        "sonic_boom",
                        "sonic_blast",
                        "acoustic_noise",
                        "thunder",
                        "avalanche",
                        "snow_avalanche",
                        "debris_avalanche",
                        "hydroacoustic_event",
                        "ice_quake",
                        "slide",
                        "landslide",
                        "rockslide",
                        "meteorite",
                        "volcanic_eruption" )
const phase_list = ("P",
                    "PKIKKIKP",
                    "PKIKKIKS",
                    "PKIKPPKIKP",
                    "PKPPKP",
                    "PKiKP",
                    "PP",
                    "PS",
                    "PcP",
                    "S",
                    "SKIKKIKP",
                    "SKIKKIKS",
                    "SKIKSSKIKS",
                    "SKKS",
                    "SKS",
                    "SKiKP",
                    "SP",
                    "SS",
                    "ScS",
                    "pP",
                    "pPKiKP",
                    "pS",
                    "pSKS",
                    "sP",
                    "sPKiKP",
                    "sS",
                    "sSKS")

const pol_list = ('U', 'D', '-', '+', '_', ' ')
const loc_types = ("HYPOCENTER", "CENTROID", "AMPLITUDE", "MACROSEISMIC", "RUPTURE_START", "RUPTURE_END")
const loc_methods = ("HYPOELLIPSE", "HypoDD", "Velest", "centroid")

const hln = ('H','L','N')
const iclist = ('A','B','D','F','G','I','J','K','M','O','P','Q','R','S','T','U','V','W','Z')
const oid = ('O','I','D')
const zne = ('Z','N','E')
const nvc = ('A','B','C','1','2','3','U','V','W')
const oidfhu = ('O','I','D','F','H','U')
const icfo = ('I','C','F','O')
const junits = ("rad", "rad/s", "rad/s2")

const geodetic_datum = ("ETRS89", "GRS 80", "JGD2011")
