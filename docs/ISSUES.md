# Known Issues

## Oustanding
* ``wseis`` cannot write a SeisData object if a channel contains no data.

## External to SeisIO
* Some data channels IDs in SeedLink are not unique or are duplicates with
different LOC fields in :id.
  + This appears to happen when one stations transmits data in real time to
  multiple networks.
  + The workaround is to always specify a location code in request strings.

## Possibly resolved
* Rarely, `SeedLink!` used to cause a Julia session to hang by failing to
  initialize a connection. (Last seen July 2017)
