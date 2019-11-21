# CoreUtils
Core utility functions that do NOT depend on custom Types. Anything in SeisIO
could depend on a function in CoreUtils, including custom Types.

## Expected Code Coverage
100% of new/changed lines

## File Naming
1. Don't add file names that exist in other directories.
2. Tests for file `($fname).(ext)` belong in `test/CoreUtils/test_($fname).(ext)`
