qml_file  = path*"/SampleFiles/XML/ISC_2011-tohoku-oki.xml"
uw_file   = path*"/SampleFiles/UW/99011116541"
suds_file = path*"/SampleFiles/SUDS/eq_wvm1.sud"


printstyled("  read_quake wrapper\n", color=:light_green)

printstyled("    QML\n", color=:light_green)
H, R = read_qml(qml_file)
Ev1 = SeisEvent(hdr = H[1], source = R[1])
Ev2 = read_quake("qml", qml_file)
@test Ev2.hdr.src == abspath(qml_file)
@test Ev2.source.src == abspath(qml_file)
Ev2.hdr.src = Ev1.hdr.src
Ev2.source.src = Ev1.source.src
@test Ev1 == Ev2

printstyled("    SUDS\n", color=:light_green)
Ev1 = readsudsevt(suds_file)
Ev2 = read_quake("suds", suds_file)
@test Ev1 == Ev2

printstyled("    UW\n", color=:light_green)
Ev1 = readuwevt(uw_file, full=true)
Ev2 = read_quake("uw", uw_file, full=true)
@test Ev1 == Ev2
