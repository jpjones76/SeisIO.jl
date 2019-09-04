.. _xml:

#############
XML Meta-Data
#############

SeisIO can parse the following XML metadata formats:
* QuakeML Version 1.2 (Quake submodule)
* StationXML Version 1.1


**********
StationXML
**********
.. function:: read_sxml(fpat [, KWs])

Read FDSN StationXML files matching string pattern **fpat** into a new SeisData
object.

| Keywords:
| ``s``: start time. Format "YYYY-MM-DDThh:mm:ss", e.g., "0001-01-01T00:00:00".
| ``t``: termination (end) time. Format "YYYY-MM-DDThh:mm:ss".
| ``msr``: (Bool) read instrument response info as MultiStageResp?

| **How often is MultiStageResp needed?**
| Virtually never.

By default, the **:resp** field of each channel contains a simple instrument
response with poles, zeros, sensitivity (**:a0**), and sensitivity frequency
(**:f0**). Very few use cases require more detail than this.

The option **msr=true** processes XML files to give full response information
at every documented stage of the acquisition process: sampling, digitization,
FIR filtering, decimation, etc.


*******
QuakeML
*******
.. function:: read_qml(fpat)
    :noindex:

Read QuakeML files matching string pattern **fpat**. Returns a tuple containing
an array of **SeisHdr** objects **H** and an array of **SeisSrc** objects **R**.
Each pair (H[i], R[i]) describes the preferred location (origin, SeisHdr) and
event source (focal mechanism or moment tensor, SeisSrc) of event **i**.

If multiple focal mechanisms, locations, or magnitudes are present in a single
Event element of the XML file(s), the following rules are used to select one of
each per event:

| **FocalMechanism**
|   1. **preferredFocalMechanismID** if present
|   2. Solution with best-fitting moment tensor
|   3. First **FocalMechanism** element
|
| **Magnitude**
|   1. **preferredMagnitudeID** if present
|   2. Magnitude whose ID matches **MomentTensor/derivedOriginID**
|   3. Last moment magnitude (lowercase scale name begins with "mw")
|   4. First **Magnitude** element
|
| **Origin**
|   1. **preferredOriginID** if present
|   2. **derivedOriginID** from the chosen **MomentTensor** element
|   3. First **Origin** element

Non-essential QuakeML data are saved to `misc` in each SeisHdr or SeisSrc object
as appropriate.
