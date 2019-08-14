SeisIO `:units` String API

# Units use case-sensitive UCUM
Please see the relevant guidelines:
* [Unified Code for Units of Measure](https://en.wikipedia.org/wiki/Unified_Code_for_Units_of_Measure) and references therein
* [BIPM](https://www.bipm.org/utils/common/pdf/si-brochure/SI-Brochure-9.pdf)
* [NIST SI guidelines](https://www.nist.gov/pml/special-publication-811/nist-guide-si-chapter-6-rules-and-style-conventions-printing-and-using), chapters 5-7

## Allowed non-SI units
Allowed non-SI unit strings are found in these tables:
* [BIPM SI brochure, Table 4.1](https://www.bipm.org/utils/common/pdf/si-brochure/SI-Brochure-9.pdf)
* [NIST SI guidelines, Table 6](https://www.nist.gov/pml/special-publication-811/nist-guide-si-chapter-5-units-outside-si)

# Common Issues

## Units formed by multiplication
Indicate multiplication of units with a single period (`.`), e.g., `N.m` for Newton meters.

## Units formed by division
Indicate division of units with an oblique stroke (`/`), e.g. `m/s` for meters per second.

## Temperature
* Don't use a degree symbol: e.g., `K` is OK, but not `°K`.
* The UCUM abbreviation for Celsius is `Cel`, not `C`.

## Powers and Exponents
* A simple integer power is denoted by an integer following a unit, e.g., `"m/s2"` is "meters per second squared", not `"m/s^2"`, `"m/s**2"`, `"m s**-2"`, ... *ad nauseam*.
* Express negative powers in unit strings using `/` to separate the numerator from the denominator, e.g., `"m/s2"`, not `"m s-2"`.

# Converting to/from UCUM units syntax
See the SeisIO utilities `units2ucum`; use the SeisIO utility `vucum` to validate strings for UCUM compliance.
