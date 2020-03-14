import Base.Libc: TmStruct
import SeisIO: buf_to_uint,
  check_for_gap!,
  dtconst,
  endtime,
  is_u8_digit,
  mk_t,
  split_id,
  stream_float,
  sμ,
  μs
