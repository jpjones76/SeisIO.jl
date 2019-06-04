# Known Issues

## Oustanding
* It's not clear whether or not `SeedLink!` works with `mode="FETCH"`. This mode
often appears to close connections immediately without returning data.
* `FDSNevq` makes no checks for redundant events; using keyword `src="all"` is
likely to yield duplicates.

## External to SeisIO
1. Some data channels IDs in SeedLink are not unique, or are duplicates with
different LOC fields in `:id`.
  * This appears to happen with stations that transmit to multiple data
  centers, e.g., jointly operated by multiple networks.
  * Workaround: set a location code in the appropriate request strings.
