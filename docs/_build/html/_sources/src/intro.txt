************
:mod:`Intro`
************
SeisIO was created as a framework for working with geophysical time series data. The project is home to an ever-expanding set of web clients and file read formats.


How SeisIO Works
================
Data are loaded into minimalist containers called SeisData and SeisObj, which track record times and other necessary quantities for further processing. SeisObj containers hold a single data channel each. SeisData containers hold multiple channels at once.

New data, including data for existing channels from new sources, can be merged into SeisData containers (or placed in new SeisData containers) using built-in Julia commands. Unwanted data channels can be removed by matching on a channel's ID, name, or index within a SeisData structure.

Data can be saved to native SeisData format or to SAC.
