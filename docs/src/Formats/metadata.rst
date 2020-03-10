##############
Metadata Files
##############
.. function:: read_meta!(S, fmt::String, filepat [, KWs])
.. function:: S = read_meta(fmt::String, filepat [, KWs])

| Read metadata in file format **fmt** matching file pattern **filestr** into S.
|
| **fmt**
| Lowercase string describing the file format. See below.
|
| **filepat**
| Read files with names matching pattern ``filepat``. Supports wildcards.
|
| **KWs**
| Keyword arguments; see also :ref:`SeisIO standard KWs<dkw>` or type ``?SeisIO.KW``.

**********************
Supported File Formats
**********************
.. csv-table::
  :header: File Format, String
  :delim: |
  :widths: 2, 1

  Dataless SEED             | dataless
  FDSN Station XML          | sxml
  SACPZ                     | sacpz
  SEED RESP                 | resp

**Warning**: Dataless SEED, SACPZ, and RESP files must be Unix text files; DOS
text files, whose lines end in "\\r\\n", will not read properly. Convert with
`dos2unix` or equivalent Windows Powershell commands.

******************
Supported Keywords
******************
.. csv-table::
  :header: KW, Used By, Type, Default, Meaning
  :delim: |
  :widths: 1, 1, 1, 1, 4

  memmap| all      | Bool      | false     | use Mmap.mmap to buffer file?
  msr   | sxml     | Bool      | false     | read full MultiStageResp?
  s     | all      | TimeSpec  |           | Start time
  t     | all      | TimeSpec  |           | Termination (end) time
  units | resp     | Bool      | false     | fill in MultiStageResp units?
        | dataless |           |           |
  v     | all      | Integer   | 0         | verbosity


**Note**: `mmap=true` improves read speed for ASCII formats but requires caution. Julia language handling of SIGBUS/SIGSEGV and associated risks is unknown and undocumented.
