A short guide to adding and structuring submodules.

# Naming
Submodule names can't contain spaces or punctuation.

# Tree Structure
| Path | Description |
|---   |--- |
| src/[Name].jl | Submodule definition file read by SeisIO.jl |
| src/Submodules/[Name] | Path to submodule [Name] |
| src/Submodules/[Name]/imports.jl | `import` statements |

You don't need to plan for PEBKAC errors, but none of the cases above are mistakes.

# Submodule or Core Code?
A submodule is recommended whenever the alternative is spaghetti code. For example:
* Many helper or utility functions that aren't useful elsewhere (RandSeis, SeisHDF, SEED, SUDS)
* Many new Type definitions (Quake, SEED, SUDS)
* Significant functionality other than I/O and processing (Quake)
* Supports both time-series data and event data (SUDS, UW)

# Submodule or Separate Package?
Please create a separate package if your code meets any of the following criteria:
* Dependencies not in Project.toml
* Performs analysis that isn't preprocessing (e.g., tomography)
* Computes derived quantities from time series (e.g., seismic attributes)
* Only used in one subfield of geophysics
* Code focuses on a specific data type (e.g., strain)
* Research code, including prototyping and unpublished algorithms
