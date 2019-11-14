import LightXML: free, parse_string
import SeisIO: KW, TimeSpec, check_for_gap!, dtconst, endtime, mk_xml!,
  parsetimewin, read_station_xml!, split_id, sxml_mergehdr!, t_win, trunc_x!
import SeisIO.Quake:event_xml!, new_qml!, write_qml!
