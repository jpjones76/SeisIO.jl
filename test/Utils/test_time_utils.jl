buf = BUF.date_buf
printstyled("  time_utils.jl\n", color=:light_green)
dstr = "2019-06-01T03:50:04.02"
dt = DateTime(dstr)
t = round(Int64, d2u(dt)*1.0e6)
nx = 12345

# Tests for mk_t
printstyled("    mk_t\n", color=:light_green)
C = randSeisChannel(s=true)
C.x = randn(nx)
mk_t!(C, nx, t)
@test C.t == [1 t; nx 0]

# Tests for t_arr
printstyled("    t_arr!\n", color=:light_green)

# String tests
t_arr!(buf, dstr)
@test buf[1:6] == Int32[2019, 152, 3, 50, 4, 20]
t_arr!(buf, dstr, digits=2, md=true)
@test buf[1:7] == Int32[2019, 6, 1, 3, 50, 4, 2]
t_arr!(buf, dstr, digits=6, md=true)
@test buf[1:7] == Int32[2019, 6, 1, 3, 50, 4, 20]
t_arr!(buf, dstr, digits=4, md=false)
@test buf[1:6] == Int32[2019, 152, 3, 50, 4, 20]

# DateTime tests
t_arr!(buf, dt)
@test buf[1:6] == Int32[2019, 152, 3, 50, 4, 20]
t_arr!(buf, dt, digits=2, md=true)
@test buf[1:7] == Int32[2019, 6, 1, 3, 50, 4, 2]
t_arr!(buf, dt, digits=6, md=true)
@test buf[1:7] == Int32[2019, 6, 1, 3, 50, 4, 20]
t_arr!(buf, dt, digits=4, md=false)
@test buf[1:6] == Int32[2019, 152, 3, 50, 4, 20]

# Time tests
t_arr!(buf, t)
@test buf[1:6] == Int32[2019, 152, 3, 50, 4, 20]
t_arr!(buf, t, digits=2, md=true)
@test buf[1:7] == Int32[2019, 6, 1, 3, 50, 4, 2]
t_arr!(buf, t, digits=6, md=true)
@test buf[1:7] == Int32[2019, 6, 1, 3, 50, 4, 20000]
t_arr!(buf, t, digits=4, md=false)
@test buf[1:6] == Int32[2019, 152, 3, 50, 4, 200]
