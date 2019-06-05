# Known Issues
If installation fails, and the problem isn't documented, please [open a new issue](https://github.com/jpjones76/SeisIO.jl/issues/). If possible, please
include a text dump with the error message.

## Oustanding
* It's not clear whether or not `SeedLink!` works with `mode="FETCH"`. This mode
sometimes appears to close connections immediately without returning data.
* `FDSNevq` makes no checks for redundant events; using keyword `src="all"` is
likely to yield duplicates.

## External to SeisIO
1. Some data channels IDs in SeedLink are not unique, or are duplicates with
different LOC fields in `:id`.
  * This appears to happen with stations that transmit to multiple data
  centers. The probable cause is that some stations are jointly operated by
  multiple networks.
  * Workaround: set a location code in the appropriate request string(s).
