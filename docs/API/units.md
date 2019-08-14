SeisIO `:units` String API

# Use SI Units
Please see the relevant guidelines:
* [BIPM](https://www.bipm.org/utils/common/pdf/si-brochure/SI-Brochure-9.pdf)
* [NIST SI guidelines](https://www.nist.gov/pml/special-publication-811/nist-guide-si-chapter-6-rules-and-style-conventions-printing-and-using), chapters 5-7

## Allowed non-SI units
Allowed non-SI unit strings are found in these tables:
* [BIPM SI brochure, Table 4.1](https://www.bipm.org/utils/common/pdf/si-brochure/SI-Brochure-9.pdf)
* [NIST SI guidelines, Table 6](https://www.nist.gov/pml/special-publication-811/nist-guide-si-chapter-5-units-outside-si)

# Clarifications to NIST/BIPM ambiguities

## Units formed by multiplication
Indicate multiplication of units with a single space (` `), e.g., `N m` for Newton meters.

## Units formed by division
Indicate division of units with an oblique stroke (`/`), e.g. `m/m` (strain).

## Temperature
Don't use a degree symbol: e.g., `C` is OK, but not `°C`.

# Powers and Exponents
* Use superscripts; create these with keyboard sequence \\^N, e.g. `s\^2` for `s²`. (Enter these manually at a prompt; they won't form superscripts if copy-pasted)
* Express negative powers in unit strings using `/` to separate the numerator from the denominator, e.g., `"m/s²"`, not `"m s⁻²"`.
* When character representation is needed, try these:
  + Char(0xb2) = `'²'`
  + Char(0xb3) = `'³'`
  + Char(0x00002074) = `'⁴'`
  +  ⋮
  + Char(0x00002079) = `'⁹'`
* Note that a `:units` string `"u"` involving a power n>3 has the property `length(u) < sizeof(u)`.
