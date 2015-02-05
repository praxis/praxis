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

      api.response_template :accepted do
        status 202
        description "The request has been accepted for processing, but the processing has not been completed."
      end

      api.response_template :no_content do
        status 204
        description "The server successfully processed the request, but is not returning any content."
      end

      api.response_template :multiple_choices do
        status 300
        description "Indicates multiple options for the resource that the client may follow."
      end

      api.response_template :moved_permanently do
        status 301
        description "This and all future requests should be directed to the given URI."
      end

      api.response_template :found do
        status 302
        description "The requested resource resides temporarily under a different URI."
      end

      api.response_template :see_other do
        status 303
        description "The response to the request can be found under another URI using a GET method"
      end

      api.response_template :not_modified do
        status 304
        description "Indicates that the resource has not been modified since the version specified by the request headers If-Modified-Since or If-Match."
      end

      api.response_template :temporary_redirect do
        status 307
        description "In this case, the request should be repeated with another URI; however, future requests should still use the original URI."
      end

      api.response_template :bad_request do
        status 400
        description "The request cannot be fulfilled due to bad syntax."
      end

      api.response_template :unauthorized do
        status 401
        description "Similar to 403 Forbidden, but specifically for use when authentication is required and has failed or has not yet been provided."
      end

      api.response_template :forbidden do
        status 403
        description "The request was a valid request, but the server is refusing to respond to it."
      end

      api.response_template :not_found do
        status 404
        description "The requested resource could not be found but may be available again in the future."
      end

      api.response_template :method_not_allowed do
        status 405
        description "A request was made of a resource using a request method not supported by that resource."
      end

      api.response_template :not_acceptable do
        status 406
        description "The requested resource is only capable of generating content not acceptable according to the Accept headers sent in the request."
      end

      api.response_template :request_timeout do
        status 408
        description "The server timed out waiting for the request."
      end

      api.response_template :conflict do
        status 409
        description "Indicates that the request could not be processed because of conflict in the request, such as an edit conflict in the case of multiple updates."
      end

      api.response_template :precondition_failed do
        status 412
        description "The server does not meet one of the preconditions that the requester put on the request."
      end

      api.response_template :unprocessable_entity do
        status 422
        description "The request was well-formed but was unable to be followed due to semantic errors."
      end

    end


  end
end
