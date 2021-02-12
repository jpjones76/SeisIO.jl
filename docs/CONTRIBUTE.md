# **How to Contribute**
0. **Please contact us first**. Describe the intended contribution(s). In addition to being polite, this ensures that you aren't doing the same thing as someone else.
1. Fork the code: in Julia, type `] dev SeisIO`.
2. Choose an appropriate branch:
  - For **bug fixes**, please use `main`.
  - For **new features** or **changes**, don't use `main`. Create a new branch or push to `dev`.
3. When ready to submit, push to your fork (please, not to `main`) and submit a Pull Request (please, not to `main`).
4. Please wait while we review the request.

# **General Rules**

## **Include tests for new code**
* We expect at least 95% code coverage on each file.
* Our target code coverage is 99% on both [CodeCov](https://codecov.io/gh/jpjones76/SeisIO.jl) and [Coveralls](https://coveralls.io/github/jpjones76/SeisIO.jl?branch=main). Code coverage has exceeded 97% consistenly since at least June 2019. Please don't break that for us.
* Good tests include a mix of [unit testing](https://en.wikipedia.org/wiki/Unit_testing) and [use cases](https://en.wikipedia.org/wiki/Use_case).

Data formats with rare encodings can be exceptions to the 95% rule.
* Example 1: SEG Y is one of four extant file formats that still uses [IBM hexadecimal Float](https://en.wikipedia.org/wiki/IBM_hexadecimal_floating_point); we've never encountered it, so we can't test it, but it exists.
* Example 2: Int24 encoding of SEED data exists in theory, but we cannot find a single researcher who's encountered it; neither can the IRIS DMC staff that we've asked. We don't support this encoding.

We understand the need to fish for digital coelocanths, but please consider
their rarity before deciding that SeisIO needs another one.

## **Don't add dependencies to the SeisIO core module**
Please keep the footprint small.

## **Write comprehensible code**
Other contributors must be able to understand your work. People must be able to
use it. Scientific software should require a Ph.D to understand the science, not
to learn the syntax.

## Please limit calls to other languages
For reasons of transparency, portability, and reproducibility, external calls must meet three conditions:
1. Works correctly in (non-emulated) Windows, Linux, and Mac OS.
1. Source code free and publicly available. "Please contact the author for the source code" emphatically **does not** meet this standard.
1. Must free pointers after use. If we can make your code trigger a segmentation fault, we have no choice but to reject it. Beware that LightXML is the reason that this rule exists; it does *not* free pointers on its own.

We strongly recommend only calling external functions for tasks with no Julia equivalent (like plotting) or whose native Julia versions behave strangely, perform poorly, or do both. (most of `Dates` does both)

### Prohibited external calls
* No software with (re)distribution restrictions, such as Seismic Analysis Code (SAC)
* No commercial software, such as MATLAB™ or Mathematica™
* No software with many contributors and no clear control process, such as ObsPy, Gnu Octave, or the Arch User Repository (AUR)
