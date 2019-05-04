import SeisIO:safe_isfile
nx_add = 1400000
nx_new = 36000
pref = path * "/SampleFiles/"
cfile = pref * "Restricted/03_02_27_20140927.sjis.ch"
files = String[ "99011116541W"                "uw"            "_"
                "test_PASSCAL.segy"           "passcal"       "pa-full"
                "test_PASSCAL.segy"           "passcal"       "passcal"
                "one_day.sac"                 "sac"           "_"
                "one_day.mseed"               "mseed"         "_"
                "Restricted/2014092709*.cnt"  "win32"         "win"
                "0215162000.c00"              "lennasc"       "_"
                "geocsv_slist.csv"            "geocsv.slist"  "_"
                "Restricted/SHW.UW.mseed"     "mseed"         "lo-mem"
                "Restricted/test_rev_1.segy"  "segy"          "full"
                "Restricted/test_rev_1.segy"  "segy"          "_"
                "test_be.sac"                 "sac"           "full"
                "test_be.sac"                 "sac"           "_"
                "FDSNWS.IRIS.geocsv"          "geocsv"        "_"      ]

# Do not run on Appveyor; it can't access restricted files, so this breaks
if Sys.iswindows() == false
  printstyled("  read_data\n", color=:light_green)
  for n = 1:size(files,1)
    fname = pref * files[n,1]
    f_call = files[n,2]
    opt = files[n,3]
    printstyled(string("    ", f_call, "\n"), color=:light_green)
    if opt == "pa-full"
      S = read_data("passcal", fname, full=true)
    elseif opt == "win"
      S = read_data(f_call, fname, cf=cfile)
    elseif opt == "slist"
      S = read_data("geocsv.slist", fname, tspair=false)
    elseif opt == "lo-mem"
      S = read_data(f_call, fname, nx_new=nx_new, nx_add=nx_add)
    elseif opt == "full"
      S = read_data(f_call, fname, full=true)
    else
      S = read_data(f_call, fname)
    end
  end
end

@test_throws ErrorException read_data("deez", "nutz.sac")
