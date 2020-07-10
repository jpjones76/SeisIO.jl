# **Web Clients and Support**
| Service                     | Submodule   | Command   | Method  |
|:-----                       |:-----       |:-----     |:-----   |
| FDSNWS dataselect           |             | get_data  | FDSN    |
| FDSNWS event with data      | Quake       | FDSNevt   |         |
| FDSNWS event search         | Quake       | FDSNevq   |         |
| FDSNWS station              |             | FDSNsta   |         |
| IRISWS timeseries           |             | get_data  | IRIS    |
| IRISPH5WS dataselect        |             | get_data  | FDSN    |
| IRISWS traveltime (TauP)    | Quake       | get_pha!  |         |
| SeedLink DATA mode          |             | seedlink  | DATA    |
| SeedLink FETCH mode         |             | seedlink  | FETCH   |
| SeedLink TIME mode          |             | seedlink  | TIME    |

## Column Guide
* **Service** is the name of the service
* **Submodule** is the submodule, if not part of SeisIO core.
  + Access using e.g., `using SeisIO.Quake` for submodule Quake.
* **Command** is the command.
* **Method** is the method positional argument.
  + This is always the first ASCII string in the command
  + Example: *get_data!(S, "FDSN", "CI.ADO..BH?")*
  + Method is case-sensitive and should be all caps

# **List of FDSN Servers**
| src=    | Base URL                              |
|:-----   |:-----                                 |
|  BGR    | http://eida.bgr.de                    |
|  EMSC   | http://www.seismicportal.eu           |
|  ETH    | http://eida.ethz.ch                   |
| GEONET  | http://service.geonet.org.nz          |
|  GFZ    | http://geofon.gfz-potsdam.de          |
|  ICGC   | http://ws.icgc.cat                    |
|  INGV   | http://webservices.ingv.it            |
|  IPGP   | http://eida.ipgp.fr                   |
|  IRIS   | http://service.iris.edu               |
|  ISC    | http://isc-mirror.iris.washington.edu |
| KOERI   | http://eida.koeri.boun.edu.tr         |
|  LMU    | http://erde.geophysik.uni-muenchen.de |
| NCEDC   | http://service.ncedc.org              |
|  NIEP   | http://eida-sc3.infp.ro               |
|  NOA    | http://eida.gein.noa.gr               |
| ORFEUS  | http://www.orfeus-eu.org              |
| RESIF   | http://ws.resif.fr                    |
| SCEDC   | http://service.scedc.caltech.edu      |
| TEXNET  | http://rtserve.beg.utexas.edu         |
|  USGS   | http://earthquake.usgs.gov            |
|  USP    | http://sismo.iag.usp.br               |

# **List of PH5 Servers**
| src=    | Base URL                              |
|:-----   |:-----                                 |
|IRISPH5  | https://service.iris.edu/ph5ws/       |

## Notes on Server List
The string in column **src=** is a case-sensitive keyword, all caps, and enclosed in double-quotes: for example, specify ETH with keyword `src="ETH"`, not src=eth or src=ETH.
