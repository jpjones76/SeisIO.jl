.. _seisdata_file_format:

*************************************
:mod:`Appendix B: SeisIO File Format`
*************************************
SeisData files can contain multiple SeisData and SeisObj instances. The specifications below describe the file structure. Files should be written in little-endian byte order.

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
  u(``8v``), unsigned ``8v``-bit integer, UInt\ ``8v``\ , uint\ ``8v``\_t
  i(``8v``), signed ``8v``-bit integer, Int\ ``8v``\ , int\ ``8v``\_t
  f(``8v``), ``8v``-bit float, Float\ ``8v``\ , float or double

File header
===========
Each SeisIO file begins with the 8-character string ``SEISDATA``, followed by a version number ``V`` and the number of objects ``J`` in the file.

.. csv-table:: File header (16 bytes)
  :header: Var, Meaning, T, N
  :widths: 5, 32, 5, 5

  ,\"SEISDATA\",c,8
  ``V``,version,f32,1
  ``J``,\# of SeisData objects in file,u32,1

SeisData object info
====================
Each SeisData object in the file begins with the number of channels (field ``n``).

.. csv-table:: Object header (8 bytes)
  :header: Var, Meaning, T, N
  :widths: 5, 32, 5, 5

  ``n``,\# of channels,u64,1

Channel data
============
Each channel in the current SeisData object has its own set of channel data.

.. csv-table:: Fixed channel information (100 bytes)
  :header: Field, T, N
  :widths: 32, 5, 5

  ``name``,c,26
  ``id``,c,15
  ``src``,c,26
  ``fs``,f64,1
  ``gain``,f64,1
  ``units``,c,26
  ``loc``,f64,5

``resp``
^^^^^^^^

.. csv-table::
  :header: Var, Meaning, T, N
  :widths: 5, 32, 5, 5

  ``z``,length of resp array,u8,1
  ``r``,response info,f64,``2*z``

Instrument responses are complex. The first *z* points of *R* hold the real part of the array; the second *R* points hold the imaginary part. Convert with

``resp = r[1:z] + im*r[z+1:2*z]``

and reshape to a two-column array with ``z`` rows. The first column of the new, complex-valued ``resp`` field are zeros, the second are poles.

``misc``
^^^^^^^^

.. csv-table::
    :header: Var, Meaning, T, N
    :widths: 5, 32, 5, 5

    ``N``,\# of keys/vals in misc,i64,1
    ``Q``,position of key separator,i64,1
      ,(misc values subloop),,
    ``k``,key separator,c,1
    ``L``,length of key string,i64,1
    ``S``,key string,u8,``L``


Pseudo-code for reading ``misc``:

::

  read N (int64)
  read Q (int64)
  store position P relative to file begin
  seek to Q relative to file begin
  read k (char)
  read L (int64)
  read S (L chars)
  split S using separator k into string array KEYS
  seek to P relative to file begin
  misc values subloop:
    for K in KEYS:
      get code (uint8)
      read V based on ID code (see table below)
      associate K,V

Each ID code is stored as a UInt8. Read and format the field value according to the the table below.

|

.. csv-table:: (misc values subloop)
  :header: Code, Var, Type, N
  :widths: 5, 5, 5, 5

  1, , c , 1
  2, ``v``, u8, 1
  , , u(``8v``), 1
  3, ``v``, u8, 1
  , , i(``8v``), 1
  4, ``v``, u8, 1
  , , f(``8v``), 1
  5, ``v``, u8, 1
  , \(a\), f(``8v``), 2
  6, ``v``, i64, 1
  , , c, ``v``
  11, ``nd``, u8 , 1
  , ``D``, i64, ``nd``
  , , c, ``sum(D)``
  12, ``v``, u8 , 1
  , ``nd``, u8 , 1
  , ``D``, i64, ``nd``
  , , u(``8v``), ``sum(D)``
  13, ``v``, u8 , 1
  , ``nd``, u8 , 1
  , ``D``, i64, ``nd``
  , , i(``8v``), ``sum(D)``
  14, ``v``, u8 , 1
  , ``nd``, u8 , 1
  , ``D``, i64, ``nd``
  , , f(``8v``), ``sum(D)``
  15, ``v``, u8 , 1
  , ``nd``, u8 , 1
  , ``D``, i64, ``nd``
  , \(a\), f(``8v``), ``2*sum(D)``
  16, ``a``, u8 , 1
  , ``nd``, u8 , 1
  , ``D``, i64, ``nd``
  , \(b\), c, ``sum(D)``


\(a\) Complex. The first half of the data are the real part; the second half are the imaginary part.

\(b\) String arrays should be split using the value of ``a`` as a character separator, then reshaped using the dimension spec array ``D``.

For UInt, Int, and Float values, including arrays of such values, ``v`` is the precision in bytes. For arrays, ``nd`` is the number of dimensions to read; ``D`` is a length-``nd`` array of values that specifies the size of each dimension.

Example: to read a value with a code of ``2``, set the precision with ``v = read(fid, UInt8)``, then read the next ``8v`` bytes into an unsigned integer.

``notes``
^^^^^^^^^

.. csv-table:: ``notes``
  :header: Value, Meaning, T, N
  :widths: 5, 32, 5, 5

  ``a``, separator, u8, 1
  ``nd``, (always 1), u8, 1
  ``L``, length of array, i64, 1
  , notes, c, ``L``

As with string arrays in ``misc``, split notes using the value of ``a`` as a character separator.

``t``
^^^^^
.. csv-table::
  :header: Value, Meaning, T, N
  :widths: 5, 32, 5, 5

  ``nt``, number of gaps, i64, 1
  ``ti``, time gap indices, f64, ``nt``
  ``tv``, time gap values, f64, ``nt``

``t`` is a two-column array, ``t = [ti tv]``.

``x``
^^^^^
.. csv-table::
  :header: Value, Meaning, T, N
  :widths: 5, 32, 5, 5

  ``nx``, length of data array, i64, 1
  ``x``, data array, f64, ``nx``
