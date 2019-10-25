export RESP_wont_read

function resp_unit_split(buf::Array{UInt8,1}, L::Int64)
  i = 1
  while i+2 < L
    if buf[i] == 0x20 && buf[i+1] == 0x2d && buf[i+2] == 0x20
      return String(buf[1:i-1])
    end
    i = i+1
  end
  return String(buf[1:L])
end

# *** FIX ME ==> version in dataless.jl is better
function parse_resp_date!(buf::Array{UInt8,1}, L::Int64, T::Array{Int16,1})
  is_u8_digit(buf[1]) || return typemax(Int64)
  fill!(T, zero(Int16))
  i = 0
  j = 1 # counter to start position in buf
  k = 1 # counter to y,j,h,m,s
  while i ≤ L
    i += 1
    if i > L
      T[k] = buf_to_int(buf, i-1, j)
      T[k] = parse(Int16, String(buf[j:i-1]))
      break
    elseif buf[i] in (0x2c, 0x2e, 0x3a)
      T[k] = buf_to_int(buf, i-1, j)
      k += 1
      k > 6 && break
      j = i+1
    end
  end
  return mktime(T)
end

function close_resp_channel!(S::SeisData, C::SeisChannel, ts::Int64, te::Int64, fname::String, ns::Int64)
  L = length(C.resp.fs)
  for f in fieldnames(MultiStageResp)
    deleteat!(getfield(C.resp, f), (ns+1):L)
  end

  i = findid(S, C.id)
  if i != 0
    t0 = isempty(S.t[i]) ? ts : S.t[i][1,2]
    if ts ≤ t0 < te
      S.resp[i] = C.resp
      S.gain[i] = C.gain
      note!(S, i, string("seed_resp, ", fname, ", overwrote :gain, :resp"))
    end
  else
    # ObsPy does this but I don't think it's safe; stage fs is not stored uniformly.
    if length(C.resp.fs) > 0
      fac = C.resp.fac[end]
      C.fs = C.resp.fs[end] * (fac > 0 ? 1/fac : 1.0)
    end
    push!(S, C)
  end

  # fill!(delay, zero(Float64))
  # fill!(fg, zero(Float64))
  # fill!(fs_in, zero(Float64))
  # fill!(gain, zero(Float64))
  # fill!(corr, zero(Float64))
  # fill!(fac, zero(Int64))
  # fill!(os, zero(Int64))

  return nothing
end

function add_stage!(C::SeisChannel, n::Int64, tfc::UInt8)
  if C.resp.stage[n] == nothing
    C.resp.stage[n] =
      if tfc == 0x41
        PZResp64()
      elseif tfc == 0x44
        CoeffResp()
      else
        GenResp()
      end
    return nothing
  end
end


function read_seed_resp!(S::GphysData, fpat::String;
  units::Bool=false)

  buf   = BUF.buf
  C     = SeisChannel(resp = MultiStageResp(12))
  R     = C.resp
  blk   = zero(UInt64)

  # Containers for parts of the response
  # nstg    = 12
  # delay = zeros(Float64, nstg)        # Estimated delay (seconds) (047F08, 057F07)
  # corr  = zeros(Float64, nstg)        # Correction applied (seconds) (047F09, 057F08)
  # fg    = zeros(Float64, nstg)        # Frequency of gain (058F05)
  # fs_in = zeros(Float64, nstg)        # Input sample rate (047F05, 057F04)
  # gain  = zeros(Float64, nstg)        # Gain (058F04)
  # fac   = zeros(Int64,   nstg)        # Decimation factor (047F06, 057F05)
  # os    = zeros(Int64,   nstg)        # Decimation offset (047F07, 057F06)
  seq_n = zero(Int64)                 # Stage sequence number (053F04, 054F04, 057F03, 058F03, 060F04, 061F03, 062F04)
  seq_n_old = zero(Int64)             # Last sequence number
  d_arr = zeros(Int16, 6)             # Date
  nmax = zero(Int64)

  # Array containers
  X = Float64[]
  D = Float64[]
  Z = ComplexF64[]
  P = ComplexF64[]

  # Unit strings containers
  units_out = ""            # Response out units lookup (041F07, 043F07, 044F07, 053F06, 054F06, 061F07, 062F06)

  if safe_isfile(fpat)
    files = [fpat]
  else
    files = ls(fpat)
  end
  for (nf, file) in enumerate(files)

    # Counters, etc.
    c = 0x00
    i = 1
    read_state = 0x00
    tfc = 0x00
    ts = zero(Int64)          # Start date (052F22)
    te = zero(Int64)          # End date (052F23)
    ND = zero(Int64)          # Number of denominators (044F11, 054F10)
    NN = zero(Int64)          # Number of coefficients (041F08, 044F08, 054F07, 061F08, 062F14)
    NZ = zero(Int64)          # Number of zeroes (043F10, 053F09)
    NP = zero(Int64)          # Number of poles (043F15, 053F14)
    a0 = one(Float64)         # A0 normalization factor (043F08, 048F05, 053F07)
    f0 = one(Float64)         # Normalization frequency (043F09, 048F06, 053F08)
    id = UInt8[]
    units_in = ""             # Response in units lookup (041F06, 043F06, 044F06, 053F05, 054F05, 061F06, 062F05)

    io = open(file, "r")
    chip = false
    while !eof(io)
      c = read(io, UInt8)

      # comment line ------------------------------
      if c == 0x23
        while c != 0x0a
          c = read(io, UInt8)
        end
      end

      # start of blockette line -------------------
      if c == 0x42
        #= format: %c%3i%c%2i, 'B', blockette_#, 'F', field_#

        Here, I map the blockette and field numbers (along with 'F') to a UInt64.
        This mapping should be unique; for any blockette blk, I expect that
        String(reinterpret(UInt8, [blk]))[1:6] = bbbFff, where bbb is
        blockette # and ff is field #
        =#
        blk  = UInt64(read(io, UInt8))
        blk |= UInt64(read(io, UInt8)) << 8
        blk |= UInt64(read(io, UInt8)) << 16
        blk |= UInt64(read(io, UInt8)) << 24
        blk |= UInt64(read(io, UInt8)) << 32
        blk |= UInt64(read(io, UInt8)) << 40
        read_state = 0x01

        # Coefficient parsing ==================================================
        if blk in (0x0000393046313630, 0x0000393046313430)
          # Numerator coefficients (061F09, 041F09)
          X = Array{Float64,1}(undef, NN)
          for n = 1:NN
            # To first non-whitespace
            if n > 1
              skip(io, 7)
            end
            c = read(io, UInt8)
            while c == 0x20
              c = read(io, UInt8)
            end
            j = get_coeff_n(io, c, buf)
            c = skip_whitespace(io, c)
            # To next newline
            k = 1
            while c != 0x0a
              buf[k] = c
              k += 1
              c = read(io, UInt8)
            end
            store_dbl!(X, buf, k, j)
          end

        elseif blk in (0x0000313146333430, 0x0000303146333530, 0x0000363146333430, 0x0000353146333530)
          # Complex zeros (043F11, 053F10) / Complex poles (043F16, 053F15)

          if blk in (0x0000313146333430, 0x0000303146333530)
            N = NZ
            Z = Array{ComplexF64,1}(undef, N)
            is_p = false
          else
            N = NP
            P = Array{ComplexF64,1}(undef, N)
            is_p = true
          end

          for n = 1:N
            # coefficient number
            if n > 1
              skip(io, 10)
            else
              skip(io, 3)
            end
            c = skip_whitespace(io, c)
            j = get_coeff_n(io, c, buf)

            # real part
            c = skip_whitespace(io, c)
            k = 1
            while c != 0x20
              buf[k] = c
              k += 1
              c = read(io, UInt8)
            end
            xr = buf_to_double(buf, k)

            # imaginary part
            c = skip_whitespace(io, c)
            k = 1
            while c != 0x20
              buf[k] = c
              k += 1
              c = read(io, UInt8)
            end
            xi = buf_to_double(buf, k)

            # store
            if is_p
              P[j] = complex(xr, xi)
            else
              Z[j] = complex(xr, xi)
            end

            # rest irrelevant
            c = to_newline(io, c)
          end

        elseif blk in (0x0000383046343530, 0x0000313146343530, 0x0000353146323630)
          # Numerator coefficients (054F08) / Denominator coefficients (054F11) / Polynomial coefficients (B062F15)
          if blk == 0x0000383046343530
            N = NN
            X = Array{Float64,1}(undef, N)
            is_n = true
          else
            N = ND
            D = Array{Float64,1}(undef, N)
            is_n = false
          end
          for n = 1:N
            # To first non-whitespace
            if n > 1
              skip(io, 10)
            else
              skip(io, 3)
            end
            c = skip_whitespace(io, c)
            j = get_coeff_n(io, c, buf)
            c = skip_whitespace(io, c)

            # To next whitesoace
            k = 1
            while c != 0x20
              buf[k] = c
              k += 1
              c = read(io, UInt8)
            end

            # Store
            if is_n
              store_dbl!(X, buf, k, j)
            else
              store_dbl!(D, buf, k, j)
            end
            c = to_newline(io, c)
          end

        else
          # To separator
          while c != 0x3a
            c = read(io, UInt8)
          end

          # To first non-whitespace
          c = skip_whitespace(io, c)
        end
      end

      # header info --------------------------------
      if read_state == 0x01
        i = 1
        while c != 0x0a
          buf[i] = c
          i += 1
          eof(io) && break
          c = read(io, UInt8)
        end
        i -= 1

        # header parsing =======================================================
        if blk in (0x0000383046333430, 0x0000373046333530)
          # A0 normalization factor (043F08, 053F07)
          a0 = buf_to_double(buf, i)

        elseif blk == 0x0000343046323530
          # Channel (052F04)
          ni = min(i,3)
          L = length(id)
          append!(id, zeros(UInt8, ni+1))
          id[L+1] = 0x2e
          unsafe_copyto!(id, L+2, buf, 1, ni)
          setfield!(C, :id, String(id))
          # println("Starting channel ", C.id)
          chip = true

        elseif blk in (0x0000383046373530, 0x0000393046373430)
          # Correction applied (seconds) (057F08) / Response correction (047F09)
          store_dbl!(R.corr, buf, i, seq_n)

        elseif blk in (0x0000353046373530, 0x0000363046373430)
          # Decimation factor (057F05) / Response decimation factor (047F06)
          store_int!(R.fac, buf, i, seq_n)

        elseif blk in (0x0000363046373530, 0x0000373046373430)
          # Decimation offset (057F06) /  Response decimation offset (047F07)
          store_int!(R.os, buf, i, seq_n)

        elseif blk == 0x0000333246323530
          # End date (052F23)
          te = parse_resp_date!(buf, i, d_arr)

        elseif blk in (0x0000373046373530, 0x0000383046373430)
          # Estimated delay (seconds) (057F07) /  Response delay (047F08)
          store_dbl!(R.delay, buf, i, seq_n)

        elseif blk in (0x0000353046383530, 0x0000363046383430)
          # Frequency of gain (058F05) / Frequency of sensitivity (048F06)
          # println("blk = ", String(reinterpret(UInt8, [blk])), ", buf = ", String(buf[1:i]))
          store_dbl!(R.fg, buf, i, seq_n)

        elseif blk in (0x0000343046383530, 0x0000353046383430)
          # Gain (058F04) / Sensitivity (048F05)
          if seq_n > 0
            store_dbl!(R.gain, buf, i, seq_n)
          else
            C.gain = buf_to_double(buf, i)
          end

        elseif blk in (0x0000343046373530, 0x0000353046373430)
          # Input sample rate (057F04) / Response input sample rate (047F05)
          store_dbl!(R.fs, buf, i, seq_n)

        elseif blk == 0x0000333046323530
          # Location (052F03)
          push!(id, 0x2e)
          for j = 1:min(i,2)
            if buf[j] != 0x3f
              push!(id, buf[j])
            end
          end

        elseif blk == 0x0000363146303530
          # Network (050F16)
          ni = min(i,2)
          prepend!(id, zeros(UInt8, ni))
          copyto!(id, 1, buf, 1, ni)

        elseif blk in (0x0000393046333430, 0x0000383046333530)
          # Normalization frequency (043F09, 053F08)
          f0 = buf_to_double(buf, i)

        elseif blk in (0x0000313146343430, 0x0000303146343530)
          # Number of denominators (044F11, 054F10)
          ND = buf_to_int(buf, i)

        elseif blk in (0x0000383046313430, 0x0000383046343430, 0x0000373046343530, 0x0000383046313630, 0x0000343146323630)
          # Number of numerators (041F08, 044F08, 054F07, 061F08) / Number of coefficients (062F14)
          NN = buf_to_int(buf, i)

        elseif blk in (0x0000353146333430, 0x0000343146333530)
          # Number of poles (043F15, 053F14)
          NP = buf_to_int(buf, i)

        elseif blk in (0x0000303146333430, 0x0000393046333530)
          # Number of zeroes (043F10, 053F09)
          NZ = buf_to_int(buf, i)

        elseif blk in (0x0000363046313430, 0x0000363046333430, 0x0000363046343430, 0x0000353046333530, 0x0000353046343530, 0x0000363046313630, 0x0000353046323630)
          # Response in units lookup (041F06, 043F06, 044F06, 053F05, 054F05, 061F06, 062F05)
          if units || isempty(C.units)
            units_in = fix_units(resp_unit_split(buf, i))
            if seq_n > 0 && units == true
              C.resp.i[seq_n] = units_in
            end
          end

        elseif blk in (0x0000373046313430, 0x0000373046333430, 0x0000373046343430, 0x0000363046333530, 0x0000363046343530, 0x0000373046313630, 0x0000363046323630)
          # Response out units lookup (041F07, 043F07, 044F07, 053F06, 054F06, 061F07, 062F06)
          if units
            units_out = fix_units(resp_unit_split(buf, i))
            if seq_n > 0
              C.resp.o[seq_n] = units_out
            end
          end

        elseif blk in (0x0000343046333530, 0x0000343046343530, 0x0000333046373530, 0x0000333046383530, 0x0000343046303630, 0x0000333046313630, 0x0000343046323630)
          # Stage sequence number (053F04, 054F04, 057F03, 058F03, 060F04, 061F03, 062F04)
          seq_n = buf_to_int(buf, i)
          nmax = max(nmax, seq_n)

          #= Here is where we dump everything to seq_n_old.

          Fortunately RESP files list stage 0 last, which makes stupid tricks
          like this viable.
          =#
          if seq_n_old != seq_n

            # initialize stage seq_n
            if seq_n > 0
              if length(C.resp.stage) < seq_n
                append!(C.resp, MultiStageResp(6))
              end
            end

            # dump to seq_n_old
            if seq_n_old > 0
              if isa(C.resp.stage[seq_n_old], CoeffResp)
                C.resp.stage[seq_n_old].b = X
                C.resp.stage[seq_n_old].a = D
                X = Float64[]
                D = Float64[]
              elseif isa(C.resp.stage[seq_n_old], PZResp64)
                C.resp.stage[seq_n_old].a0 = a0
                C.resp.stage[seq_n_old].f0 = f0
                C.resp.stage[seq_n_old].z = Z
                C.resp.stage[seq_n_old].p = P
                Z = ComplexF64[]
                P = ComplexF64[]
                a0 = one(Float64)
                f0 = one(Float64)
              end
            end

            seq_n_old = seq_n
          end

          # trigger new channel on seq_n
          if blk in (0x0000343046333530, 0x0000343046343530, 0x0000343046323630)
            if seq_n > 0 && tfc != 0x00
              add_stage!(C, seq_n, tfc)
              tfc = 0x00
            end
          end

        elseif blk == 0x0000323246323530
          # Start date (052F22)
          ts = parse_resp_date!(buf, i, d_arr)

        elseif blk == 0x0000333046303530
          # Station (050F03)
          if chip
            # close_resp_channel!(S, C, ts, te, file, corr, delay, fg, fs_in, gain, fac, os, length(C.resp.stage))
            close_resp_channel!(S, C, ts, te, file, nmax)
            C = SeisChannel(resp = MultiStageResp(12))
            R = C.resp
            chip = false
            seq_n = zero(Int64)
            seq_n_old = zero(Int64)
            tfc = 0x00
            units_in = ""
            nmax = zero(Int64)
          end
          ni = min(i,5)
          id = zeros(UInt8, ni+1)
          unsafe_copyto!(id, 2, buf, 1, ni)
          id[1] = 0x2e

        elseif blk in (0x0000353046333430, 0x0000353046343430, 0x0000333046333530, 0x0000333046343530, 0x0000333046323630)
          # Response type (043F05, 044F05) / Transfer function type (053F03, 054F03, 062F03)
          tfc = buf[1]

          # trigger on response type
          if blk in (0x0000353046333430, 0x0000353046343430)
            if seq_n > 0
              add_stage!(C, seq_n, tfc)
              tfc = 0x00
            end
          end

        elseif blk in (0x0000353046313430, 0x0000353046313630)
          # Symmetry type (041F05, 061F05) tells us we have a digital filter
          tfc = 0x44
          if seq_n > 0
            add_stage!(C, seq_n, tfc)
            tfc = 0x00
          end

        end

        if seq_n == 1 && isempty(C.units) && !isempty(units_in)
          C.units = units_in
          units_in = ""
        end

        read_state = 0x00
      end
    end
    close(io)
    close_resp_channel!(S, C, ts, te, file, nmax)
    if nf != lastindex(files)
      C = SeisChannel(resp = MultiStageResp(12))
      R = C.resp
      chip = false
      seq_n = zero(Int64)
      seq_n_old = zero(Int64)
      tfc = 0x00
      units_in = ""
      nmax = zero(Int64)
    end
  end
  return S
end

function read_seed_resp(fpat::String;
  units::Bool=false)
  S = SeisData()
  read_seed_resp!(S, fpat, units=units)
  return S
end

"""
    RESP_wont_read()

The following is a list of breaking SEED RESP issues that we've encountered
in real data. Files with these issues don't read correctly into any known
program (e.g., ObsPy, SAC, SeisIO).

| Network | Station(s)    | Problem(s)
| :----   | :----         | :----
| CN      | (broadbands)  | B058F05-06 contain units; should be B053F05-06
"""
function RESP_wont_read()
  return nothing
end
