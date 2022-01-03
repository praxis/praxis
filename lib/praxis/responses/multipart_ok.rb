# frozen_string_literal: true

module Praxis
  module Responses
    class MultipartOk < Ok
      def initialize(status: self.class.status, headers: {}, body: '')
        @name    = response_name
        @status  = status
        @headers = headers
        @body    = body
      end

      def handle
        case @body
        when Praxis::Types::MultipartArray
          @headers['Content-Type'] = @body.content_type if @headers['Content-Type'].nil?
        end
      end

      def encode!
        case @body
        when Praxis::Types::MultipartArray
          @body = @body.dump
        else
          super
        end
      end

      def finish
        format!
        encode!

        @body = Array(@body)

        [@status, @headers, @body]
      end
    end
  end

  ApiDefinition.define do |api|
    api.response_template :multipart_ok do |media_type: Praxis::Types::MultipartArray|
      status 200
      media_type media_type
    end
  end
end
