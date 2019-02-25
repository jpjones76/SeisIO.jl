.. _seisdata_file_format:

##################
SeisIO File Format
##################
Files are written in little-endian byte order.

.. csv-table:: Abbreviations used in this section
  :header: Var, Meaning, Julia, C ``\<stdint.h\>``
  :widths: 3, 10, 5, 7

  c, unsigned 8-bit character, Char, unsigned char
  f32, 32-bit float, Float32, float
  f64, 64-bit float, Float64, double
  i64, signed 64-bit integer, Int64, int64_t
  u8, unsigned 8-bit int, UInt8, uint8_t
  u32, unsigned 32-bit int, UInt32, int32_t
  u64, unsigned 64-bit int, UInt64, uint64_t
  u(8), unsigned 8-bit integer, UInt\ 8\ , uint\ 8\_t
  i(8), signed 8-bit integer, Int\ 8\ , int\ 8\_t
  f(8), 8-bit float, Float\ 8\ , float or double

***********
File header
***********

.. csv-table:: File header (14 bytes + TOC)
  :header: Var, Meaning, T, N
  :widths: 5, 32, 5, 5

  ,\"SEISIO\",c,6
  ``V``,SeisIO version,f32,1
  ``jv``,Julia version,f32,1
  ``J``,\# of SeisIO objects in file,u32,1
  ``C``,Character codes for each object,c,J
  ``B``,Byte indices for each object,u64,J

The Julia version stores VERSION.major.VERSION.minor as a Float32, e.g. v0.5 is stored as 0.5f0; SeisIO version is stored similarly.

.. csv-table:: Object codes
  :header: Char, Meaning
  :widths: 5, 25

  'D', SeisData
  'H', SeisHdr
  'E', SeisEvent

*******
SeisHdr
*******
Structural overview:
::

  Int64_vals
  :mag[1]       # Float32
  Float64_vals
  UInt8_vals
  :misc

.. csv-table:: Int64 values
  :header: Var, Meaning
  :widths: 1, 4

  id, event id
  ot, origin time in integer μs from Unix epoch
  L_int, length of intensity scale string
  L_src, length of src string
  L_notes, length of notes string

Magnitude is stored as a Float32 after the Int64 values.

.. csv-table:: Float64 values
  :header: Var, N, Meaning
  :widths: 1, 1, 8
  :delim: |

  loc | 3 | lat, lon, dep
  mt  | 8 | tensor, scalar moment, %dc
  np  | 6 | np (nodal planes: 1st, 2nd)
  pax | 9 | pax (principal axes: P, T, N)

.. csv-table:: UInt8 values
  :header: Var, N, Meaning
  :widths: 1, 1, 4

  msc, 2, magnitude scale characters
  c, 1, separator for notes
  i, 1, intensity value
  i_sc, L_int, intensity scale string
  src, L_src, ``:src`` as a string
  notes, L_notes, ``:notes`` joined a string with delimiter ``c``

Entries in Misc are stored after UInt8 values. See below for details.

********
SeisData
********
Structural overview:
::

  S.n           # UInt32
  # Repeated for each channel
  Int64_vals
  Float64_vals
  UInt8_vals    # including compressed S.x
  :misc

S.x is compressed with BloscLZ before writing to disk.

Channel data
============
.. csv-table:: Int64 values
  :header: Var, N, Meaning
  :widths: 1, 2, 10

  L_t, , length(S.t)
  r,  , length(S.resp)
  L_units,  , length(S.units)
  L_src,  , length(S.src)
  L_name,  , length(S.name)
  L_notes,  , length of notes string
  lxc,  , length of BloscLZ-compressed S.x
  L_x,  , length(S.x)
  t, L_t, S.t

.. csv-table:: Float64 values
  :header: Var, N, Meaning
  :widths: 1, 2, 8
  :delim: |

  fs    | 1   | S.fs
  gain  | 1   | S.gain
  loc   | 5   | S.loc (lat, lon, dep, az, inc)
  resp  | 2*r | real(S.resp[:]) followed by imag(S.resp[:])

Convert resp with ``resp = rr[1:r] + im*rr[r+1:2*r]`` and reshape to a two-column array with ``r`` rows. The first column of the new, complex-valued ``resp`` field holds zeros, the second holds poles.

.. csv-table:: UInt8 values
  :header: Var, N, Meaning
  :widths: 1, 1, 4

  c, 1, separator for notes
  ex, 1, type code for S.x
  id, 15, S.id
  units, L_units, S.units
  src, L_src, S.src
  name, L_name, S.name
  notes, L_notes, S.notes joined as a string with delimiter ``c``
  xc, lxc, Blosc-compressed S.x

S.misc is written last, after the compressed S.x

Storing misc
============
``:misc`` is a Dict{String,Any} for both SeisData and SeisHdr, with limited support for key value types. Structural overview:
::

  L_keys
  char_separator  # for keys
  keys            # joined as a string
  # for each key k
  type_code       # UInt8 code for misc[k]
  value           # value of misc[k]

.. csv-table:: ``:misc`` keys
    :header: Var, Meaning, T, N
    :widths: 5, 32, 5, 5

    ``L``,length of keys string,i64,1
    ``p``,character separator,u8,1
    ``K``,string of keys,u8,p


.. _smt:

.. csv-table:: Supported ``:misc`` value Types
    :header: code, value Type, code, value Type
    :widths: 1, 6, 1, 6
    :delim: |

    0    |Char              |128  |Array{Char,1}
    1    |String		|129  |Array{String,1}
    16   |UInt8		|144  |Array{UInt8,1}
    17   |UInt16		|145  |Array{UInt16,1}
    18   |UInt32		|146  |Array{UInt32,1}
    19   |UInt64		|147  |Array{UInt64,1}
    20   |UInt128		|148  |Array{UInt128,1}
    32   |Int8		|160  |Array{Int8,1}
    33   |Int16		|161  |Array{Int16,1}
    34   |Int32		|162  |Array{Int32,1}
    35   |Int64		|163  |Array{Int64,1}
    36   |Int128		|164  |Array{Int128,1}
    48   |Float16		|176  |Array{Float16,1}
    49   |Float32		|177  |Array{Float32,1}
    50   |Float64		|178  |Array{Float64,1}
    80   |Complex{UInt8}	|208  |Array{Complex{UInt8},1}
    81   |Complex{UInt16}	|209  |Array{Complex{UInt16},1}
    82   |Complex{UInt32}	|210  |Array{Complex{UInt32},1}
    83   |Complex{UInt64}	|211  |Array{Complex{UInt64},1}
    84   |Complex{UInt128}	|212  |Array{Complex{UInt128},1}
    96   |Complex{Int8}	|224  |Array{Complex{Int8},1}
    97   |Complex{Int16}	|225  |Array{Complex{Int16},1}
    98   |Complex{Int32}	|226  |Array{Complex{Int32},1}
    99   |Complex{Int64}	|227  |Array{Complex{Int64},1}
    100  |Complex{Int128}	|228  |Array{Complex{Int128},1}
    112  |Complex{Float16}	|240  |Array{Complex{Float16},1}
    113  |Complex{Float32}	|241  |Array{Complex{Float32},1}
    114  |Complex{Float64}	|242  |Array{Complex{Float64},1}


Julia code for converting between data types and UInt8 type codes is given below.
::

  findtype(c::UInt8, T::Array{Type,1}) = T[findfirst([sizeof(i)==2^c for i in T])]
  function code2typ(c::UInt8)
    t = Any::Type
    if c >= 0x80
      t = Array{code2typ(c-0x80)}
    elseif c >= 0x40
      t = Complex{code2typ(c-0x40)}
    elseif c >= 0x30
      t = findtype(c-0x2f, Array{Type,1}(subtypes(AbstractFloat)))
    elseif c >= 0x20
      t = findtype(c-0x20, Array{Type,1}(subtypes(Signed)))
    elseif c >= 0x10
      t = findtype(c-0x10, Array{Type,1}(subtypes(Unsigned)))
    elseif c == 0x01
      t = String
    elseif c == 0x00
      t = Char
    else
      t = Any
    end
    return t
  end

  tos(t::Type) = round(Int64, log2(sizeof(t)))
  function typ2code(t::Type)
    n = 0xff
    if t == Char
      n = 0x00
    elseif t == String
      n = 0x01
    elseif t <: Unsigned
      n = 0x10 + tos(t)
    elseif t <: Signed
      n = 0x20 + tos(t)
    elseif t <: AbstractFloat
      n = 0x30 + tos(t)-1
    elseif t <: Complex
      n = 0x40 + typ2code(real(t))
    elseif t <: Array
      n = 0x80 + typ2code(eltype(t))
    end
    return UInt8(n)
  end

Type "Any" is provided as a default; it is not supported.


Standard Types in ``:misc``
---------------------------
Most values in ``:misc`` are saved as a :ref:`UInt8 code <smt>` followed by the value itself.


Unusual Types in ``:misc``
--------------------------
The tables below describe how to read non-bitstype data into ``:misc``.

.. csv-table:: Array{String}
    :header: Var, Meaning, T, N
    :widths: 4, 32, 4, 4

    nd,array dimensionality,u8,1
    d,array dimensions,i64,nd
    ,if d!=[0]:,,
    sep,string separator,c,1
    L_S,length of char array,i64,1
    S,string array as chars,u8,L_S

If d=[0], indicating an empty String array, set S to an empty String array and do not read sep, L_S, or S.

.. csv-table:: Array{Complex}
    :header: Var, Meaning, T, N
    :widths: 4, 32, 4, 4

    nd,array dimensionality,u8,1
    d,array dimensions,i64,nd
    rr,real part of array, τ, d
    ii,imaginary part of array, τ, d

Here, τ denotes the type of the real part of one element of v.

.. csv-table:: Array{Real}
    :header: Var, Meaning, T, N
    :widths: 4, 32, 4, 4

    nd,array dimensionality,u8,1
    d,array dimensions,i64,nd
    v,array values, τ, d

Here, τ denotes the type of one element of v.

.. csv-table:: String
    :header: Var, Meaning, T, N
    :widths: 4, 32, 4, 4

    L_S,length of string,i64,1
    S,string,u8,L_S


*********
SeisEvent
*********
A SeisEvent structure is stored as a SeisHdr object followed by a SeisData object. However, the combination of SeisHdr and SeisData objects that comprises a SeisEvent object counts as one object, not two, in the file TOC.
