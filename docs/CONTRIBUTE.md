# **How to Contribute**
SeisIO welcomes contributions, but users should follow the rules below.

## **Recommended Contribution Procedure**
0. **Please contact us first**. Describe the intended contribution(s). In addition to being polite, this ensures that you aren't doing the same thing as someone else.
1. Fork the code: in Julia, type `] dev SeisIO`.
2. Choose an appropriate branch:
  - For **bug fixes**, please use `master`.
  - For **new features**, please create a new branch or push to `dev`.
3. When ready to submit, push to your fork and submit a Pull Request.
4. Please wait a week while we review the request.

# **General Rules**

## Include tests
* Your tests must pass before your code can be merged.
* Good tests include a mix of unit tests and typical "use" cases.
* Place tests in appropriate subdirectories of `test`.
* Files added to (or changed in) `src` must have code coverage ≥95% in both [codecov.io](https://codecov.io) and [coveralls.io](https://coveralls.io).

## Don't make [spaghetti code](https://en.wikipedia.org/wiki/Spaghetti_code)
* Code should be comprehensible and well-organized.
* Please don't use intentionally arcane syntax or create gibberish with [metaprogramming](https://docs.julialang.org/en/v1/manual/metaprogramming/index.html).
* Please don't nest wrapper functions.

## Don't call other languages needlessly
External program calls should only happen when necessary and are only permitted if the source code of what you're calling is free and available to the public.

External calls to the following are forbidden:
* Wrapper functions to different languages
* Software with (re)distribution restrictions, such as Seismic Analysis Code (SAC)
* Commercial software, such as MATLAB
* Python
* R

## No new dependencies
This rule does not apply to submodules.

# **Additional Processing/Analysis Rules**
In addition to the above, code for data processing or analysis must conform to the following specifications:

## Leave unprocessed data channels alone
Skip channels with data types or properties that are incompatible with your code; never delete or alter them. For example, code that assumes regularly-sampled data should skip irregularly-sampled channels (the best way to identify channels with regularly-sampled data is `findall(S.fs) .> 0.0`).

## Don't assume ideal SeisData objects
Your code must handle (or skip, as needed) channels in SeisData objects that have one or more of these undesirable features:
* irregularly-sampled data
* time gaps of arbitrary lengths
* time-series segments of any length > 0, i.e., as short as a single data point between two gaps, or as long as memory limitations allow
* unusual instrument types (e.g. timing channels, radiometers, resistivity)
* empty `:resp` fields
* empty or unusual `:loc` fields (there is no universal standard for describing a scientific instrument's position; code accordingly)

## Don't assume a processing work flow
A routine that assumes prior processing should incorporate it. A routine that assumes a great deal of prior processing should probably be a private script unless the work flow is a widely recognized standard procedure.

## Ensure that data-specific code finds the right data
Include a means of testing that data come from the intended instrument types.

### Identifying instrument type
SeisIO uses SEED channel naming conventions for the `:id` field of most geophysical data. Thus, there are two ways to check whether channel data matches the desired instrument type:
1. (Preferred) Get the single-character "channel instrument code" for channel `i` with ``split(S.id[i], '.')[4][2]``; compare with [standard SEED instrument codes](https://ds.iris.edu/ds/nodes/dmc/data/formats/seed-channel-naming/). This can break for non-SEED IDs, so enclosing this comparison in a `try/catch` loop might be necessary.
2. Check `:units`. This is not always a good idea because some sources list units in "counts" (e.g., "counts/s", "counts/s**2") when the "stage zero" gain is included; this convention is useless and confusing but technically precise.

# **Notes and Discussion**

#### Why no Python calls in SeisIO core?
- Opacity: Python packages can be distributed in a precompiled state; source code is not always available, which violates the transparency requirement.
- Overhead: PyCall consumes >70 MB in Julia v1.1; PyPlot consumes >130 MB. Python code is not optimized for Julia, obviously; that can add overhead or slowdown.
- Spaghetti code: mature Python packages often install dozens of dependencies, trading several GB disk space for a handful of functions. (Their "ecosystem" is more like a superfund site...)

#### Why no R calls in SeisIO core?
- Because R is not a fast language, performant R packages are thin wrapper functions to C++ and/or Java, which violates the rule "no external calls to wrapper functions to different languages".
