.. _xml:

#############
XML Meta-Data
#############

SeisIO can read and write the following XML metadata formats:
* QuakeML Version 1.2
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

.. function:: write_sxml(fname::String, S::GphysData[, chans=Cha])

Write station XML from the fields of **S** to file **fname**.

Use keyword **chans=Cha** to restrict station XML write to **Cha**. This
keyword can accept an Integer, UnitRange, or Array{Int64,1} argument.

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

.. function:: write_qml(fname, SHDR::Array{SeisHdr,1}, SSRC::Array{SeisSrc,1}; v::Int64=0)
.. function:: write_qml(fname, SHDR::SeisHdr, SSRC::SeisSrc; v::Int64=0)
    :noindex:

.. function:: write_qml(fname, SHDR::SeisHdr; v::Int64=0)
.. function:: write_qml(fname, SHDR::Array{SeisHdr,1}; v::Int64=0)
    :noindex:

Write QML to **fname** from **SHDR**.

If **fname** exists, and is QuakeML, SeisIO appends the existing XML. If the
file is NOT QuakeML, an error is thrown; the file isn't overwritten.

.. function:: write_qml(fname, SHDR::SeisHdr, SSRC::SeisSrc; v::Int64=0)
    :noindex:
.. function:: write_qml(fname, SHDR::Array{SeisHdr,1}, SSRC::Array{SeisSrc,1}; v::Int64=0)
    :noindex:

Write QML to **fname** from **SHDR** and **SSRC**.

**Warning**: to write data from a SeisSrc object R in SSRC, it must be true
that R.eid == H.id for some H in SHDR.
