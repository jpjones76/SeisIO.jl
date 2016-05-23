.. _utils:

***********************************
:mod:`Appendix C: Utility Programs`
***********************************
A few utility programs are included with SeisIO.

``plotseis(S)``: Plot time-aligned trace data from SeisData structure ``S``.

``randseis()``: Generate a SeisObj structure with pseudo-random headers and data. Specify ``c=false`` to allow campaign-style channels with ``fs=0``. Specify an integer argument to set the number of channels; otherwise, ``S.n`` varies from 12 to 24.

``randseisobj()``: Generate a SeisData structure with pseudo-random headers and data.

``getbandcode(fs, fc=FC)``: Generate a valid FDSN-compliant one-character band code for data sampled at ``fs``; corner frequency ``FC`` is optional.

``tx = t_expand(t)``: Expand sparse delta-encoded time representation ``t`` to generate time stamps for for each value in the corresponding data ``x``.

``t = t_collapse(tx)``: Collapse time stamp array ``tx`` to sparse delta-encoded time representation ``t``.

``j = md2j(y,m,d)``: Convert month ``m``, day ``d`` of year ``y`` to Julian day (day of year) ``j``. Not included in the Julia DateTime library.

``m,d = j2md(y,j)``: Convert Julian day (day of year) ``j`` of year ``y`` to month ``m``, day ``d``. Not included in the Julia DateTime library.
