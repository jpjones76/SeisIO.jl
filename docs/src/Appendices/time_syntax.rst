.. _timespec:

###########
Time Syntax
###########
Functions that allow time specification use two reserved keywords or arguments to track time:

* *s*: Start (begin) time
* *t*: Termination (end) time

Specify each as a DateTime, Real, or String.

* Real numbers are interpreted as seconds. Special behavior is invoked when both *s* and *t* are of Type Real.

* DateTime values should follow `Julia documentation\ <https://docs.julialang.org/en/v1/stdlib/Dates/>`_

* Strings have the expected format spec ``YYYY-MM-DDThh:mm:ss.ssssss``

  * Fractional second is optional and accepts up to 6 decimal places (μs)

  * Incomplete time Strings treat missing fields as 0.

  * Example: `s="2016-03-23T11:17:00.333"`

It isn't necessary to choose values so that *s* ≤ *t*. The two values are always sorted, so that *t* < *s* doesn't error.

***********************
Time Types and Behavior
***********************

.. csv-table::
  :header: typeof(s), typeof(t), Behavior
  :delim: |
  :widths: 1, 1, 4

  DateTime  | DateTime  | convert to String, then sort
  DateTime  | Real      | add *t* seconds to *s*, convert to String, then sort
  DateTime  | String    | convert *s* to String, then sort
  Real      | DateTime  | add *s* seconds to *t*, convert to String, then sort
  Real      | Real      | treat as relative (see below), convert to String, sort
  Real      | String    | add *s* seconds to *t*, convert to String, then sort
  String    | DateTime  | convert *t* to String, then sort
  String    | Real      | add *t* seconds to *s*, convert to String, then sort
  String    | String    | sort

Special Behavior with two Real arguments
========================================
If *s* and *t* are both Real numbers, they're treated as seconds measured relative to the *start of the current minute*. This convention may seem unusual, but it greatly simplifies web requests; for example, specifying *s=-1200.0, t=0.0* is a convenient shorthand for "the last 20 minutes of data".
