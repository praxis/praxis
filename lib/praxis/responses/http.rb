module Praxis

  module Responses

    # Descriptions from http://en.wikipedia.org/wiki/List_of_HTTP_status_codes

    # Standard response for successful HTTP requests.
    # The actual response will depend on the request method used.
    # In a GET request, the response will contain an entity
    # corresponding to the requested resource.
    # In a POST request the response will contain an entity
    # describing or containing the result of the action.
    class Ok < Praxis::Response
      self.status = 200
    end

    # The request has been fulfilled and resulted in a new resource
    # being created.
    class Created < Praxis::Response
      self.status = 201
    end


    # The request has been accepted for processing, but the
    # processing has not been completed. The request might or might
    # not eventually be acted upon, as it might be disallowed when
    # processing actually takes place.
    class Accepted < Praxis::Response
      self.status = 202
    end


    # The server successfully processed the request, but is not
    # returning any content. Usually used as a response to
    # a successful delete request.
    class NoContent < Praxis::Response
      self.status = 204
    end


    # Indicates multiple options for the resource that the client may follow. It, for instance, could be used to present different format options for video, list files with different extensions, or word sense disambiguation.
    class MultipleChoices < Praxis::Response
      self.status = 300
    end


    # This and all future requests should be directed to the given URI.
    class MovedPermanently < Praxis::Response
      self.status = 301
    end


    # This is an example of industry practice contradicting the standard. The HTTP/1.0 specification (RFC 1945) required the client to perform a temporary redirect (the original describing phrase was "Moved Temporarily"),[5] but popular browsers implemented 302 with the functionality of a 303 See Other. Therefore, HTTP/1.1 added self.status = codes 303 and 307 to distinguish between the two behaviours.[6] However, some Web applications and frameworks use the 302 self.status = code as if it were the 303.[7]
    class Found < Praxis::Response
      self.status = 302
    end


    # The response to the request can be found under another URI using a GET method. When received in response to a POST (or PUT/DELETE), it should be assumed that the server has received the data and the redirect should be issued with a separate GET message.
    class SeeOther < Praxis::Response
      self.status = 303
    end


    # Indicates that the resource has not been modified since the version specified by the request headers If-Modified-Since or If-Match. This means that there is no need to retransmit the resource, since the client still has a previously-downloaded copy.
    class NotModified < Praxis::Response
      self.status = 304
    end


    # In this case, the request should be repeated with another URI; however, future requests should still use the original URI. In contrast to how 302 was historically implemented, the request method is not allowed to be changed when reissuing the original request. For instance, a POST request should be repeated using another POST request.[10]
    class TemporaryRedirect < Praxis::Response
      self.status = 307
    end


    # The request cannot be fulfilled due to bad syntax.
    class BadRequest < Praxis::Response
      self.status = 400
    end


    # Similar to 403 Forbidden, but specifically for use when authentication is required and has failed or has not yet been provided. The response must include a WWW-Authenticate header field containing a challenge applicable to the requested resource. See Basic access authentication and Digest access authentication.
    class Unauthorized < Praxis::Response
      self.status = 401
    end


    # The request was a valid request, but the server is refusing to respond to it. Unlike a 401 Unauthorized response, authenticating will make no difference.
    class Forbidden < Praxis::Response
      self.status = 403
    end


    # The requested resource could not be found but may be available again in the future. Subsequent requests by the client are permissible.
    class NotFound < Praxis::Response
      self.status = 404
    end


    # A request was made of a resource using a request method not supported by that resource; for example, using GET on a form which requires data to be presented via POST, or using PUT on a read-only resource.
    class MethodNotAllowed < Praxis::Response
      self.status = 405
    end


    # The requested resource is only capable of generating content not acceptable according to the Accept headers sent in the request.
    class NotAcceptable < Praxis::Response
      self.status = 406
    end

    # The server timed out waiting for the request.
    class RequestTimeout < Praxis::Response
      self.status = 408
    end

    # Indicates that the request could not be processed because of conflict in the request, such as an edit conflict in the case of multiple updates.
    class Conflict < Praxis::Response
      self.status = 409
    end


    # The server does not meet one of the preconditions that the requester put on the request.
    class PreconditionFailed < Praxis::Response
      self.status = 412
    end


    # The request was well-formed but was unable to be followed due to semantic errors.[3]
    class UnprocessableEntity < Praxis::Response
      self.status = 422
    end

    ApiDefinition.define do |api|


      [
        [ :accepted, 202, "The request has been accepted for processing, but the processing has not been completed." ],
        [ :no_content, 204,"The server successfully processed the request, but is not returning any content."],
        [ :multiple_choices, 300,"Indicates multiple options for the resource that the client may follow."],
        [ :moved_permanently, 301,"This and all future requests should be directed to the given URI."],
        [ :found, 302,"The requested resource resides temporarily under a different URI."],
        [ :see_other, 303,"The response to the request can be found under another URI using a GET method"],
        [ :not_modified, 304,"Indicates that the resource has not been modified since the version specified by the request headers If-Modified-Since or If-Match."],
        [ :temporary_redirect, 307,"In this case, the request should be repeated with another URI; however, future requests should still use the original URI."],
        [ :bad_request, 400,"The request cannot be fulfilled due to bad syntax."],
        [ :unauthorized, 401,"Similar to 403 Forbidden, but specifically for use when authentication is required and has failed or has not yet been provided."],
        [ :forbidden, 403,"The request was a valid request, but the server is refusing to respond to it."],
        [ :not_found, 404,"The requested resource could not be found but may be available again in the future."],
        [ :method_not_allowed, 405,"A request was made of a resource using a request method not supported by that resource."],
        [ :not_acceptable, 406,"The requested resource is only capable of generating content not acceptable according to the Accept headers sent in the request."],
        [ :request_timeout, 408,"The server timed out waiting for the request."],
        [ :conflict, 409, "Indicates that the request could not be processed because of conflict in the request, such as an edit conflict in the case of multiple updates."],
        [ :precondition_failed, 412,"The server does not meet one of the preconditions that the requester put on the request."],
        [ :unprocessable_entity, 422,"The request was well-formed but was unable to be followed due to semantic errors."],
      ].each do |name, code, base_description|
        api.response_template name do |media_type: nil, location: nil, headers: nil, description: nil|
          status code
          description( description || base_description ) # description can "potentially" be overriden in an individual action.

          media_type media_type if media_type
          location location if location
          headers&.each do |(name, value)|
            header(name: name, value: value)
          end
        end
      end

    end


  end
end
