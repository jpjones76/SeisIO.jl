import SeisIO: get_HTTP_req, webhdr, datareq_summ

d1 = "2019-03-14T02:18:00"
d2 = "2019-03-14T02:28:00"
to = 30

# From FDSN the response code is 200
url = "http://service.iris.edu/fdsnws/dataselect/1/query?quality=B&format=miniseed&net=UW&sta=XNXNX&loc=99&cha=QQQ&start="*d1*"&end="*d2*"&szsrecs=true"
req_info_str = datareq_summ("FDSNWS data", "UW.XNXNX.99.QQQ", d1, d2)
(req, parsable) = get_HTTP_req(url, req_info_str, to, status_exception=false)
@test typeof(req) == Array{UInt8,1}
@test startswith(String(req), "HTTP.Messages.Response")
@test parsable == false

(req,parsable) = get_HTTP_req(url, req_info_str, to, status_exception=true)
@test typeof(req) == Array{UInt8,1}
@test startswith(String(req), "HTTP.Messages.Response")
@test parsable == false

# From IRIS the response code is 400 and we can get an error
url = "http://service.iris.edu/irisws/timeseries/1/query?net=DE&sta=NENA&loc=99&cha=LUFTBALLOONS&start="*d1*"&end="*d2*"&scale=AUTO&output=miniseed"
req_info_str = datareq_summ("IRISWS data", "DE.NENA.99.LUFTBALLOONS", d1, d2)
(req,parsable) = get_HTTP_req(url, req_info_str, to, status_exception=false)
@test typeof(req) == Array{UInt8,1}
@test startswith(String(req), "HTTP.Messages.Response")

(req,parsable) = get_HTTP_req(url, req_info_str, to, status_exception=true)
@test typeof(req) == Array{UInt8,1}
@test occursin("HTTP/1.1 400 Bad Request", String(req))
