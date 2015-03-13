HTTP = require("http")
HTTPS = require("https")


# Capture original HTTP request. PassThrough proxy uses that.
httpRequest  = HTTP.request
httpsRequest = HTTPS.request

passThrough = (allow)->
  if arguments.length == 0
    allow = -> true
  else if typeof allow == "string"
    [hostname, allow] = [allow, (request)-> request.hostname == hostname]
  else unless typeof allow == "function"
    [boolean, allow] = [allow, (request)-> !!boolean]

  return (request, callback)->
    if allow(request)
      options =
        cert:               request.cert
        headers:            request.headers
        hostname:           request.url.hostname
        key:                request.key
        method:             request.method
        path:               request.path
        port:               request.url.port
        protocol:           request.url.protocol
        rejectUnauthorized: request.rejectUnauthorized
        secureOptions:      request.secureOptions
        secureProtocol:     request.secureProtocol

      if request.url.protocol == "https:"
        http = httpsRequest(options)
      else
        http = httpRequest(options)
      http.on "error", (error)->
        callback error
      http.on "response", (response)->
        captured =
          version: response.httpVersion
          status:  response.statusCode
          headers: response.headers
          body:    []
        response.on "data", (chunk)->
          captured.body.push chunk
        response.on "end", ->
          captured.trailers = response.trailers
          callback null, captured
      if request.body
        for part in request.body
          http.write part[0], part[1]
      http.end()
    else
      callback null


module.exports = passThrough
