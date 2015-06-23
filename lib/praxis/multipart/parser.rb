require 'rack/utils'

# stolen from Rack::Multipart::Parser

module Praxis
  class MultipartParser
    EOL = "\r\n".freeze
    MULTIPART_BOUNDARY = "AaB03x".freeze
    MULTIPART = %r|\Amultipart/.*boundary=\"?([^\";,]+)\"?|n.freeze
    TOKEN = /[^\s()<>,;:\\"\/\[\]?=]+/.freeze
    CONDISP = /Content-Disposition:\s*#{TOKEN}\s*/i.freeze
    DISPPARM = /;\s*(#{TOKEN})=("(?:\\"|[^"])*"|#{TOKEN})/.freeze
    RFC2183 = /^#{CONDISP}(#{DISPPARM})+$/i.freeze
    BROKEN_QUOTED = /^#{CONDISP}.*;\sfilename="(.*?)"(?:\s*$|\s*;\s*#{TOKEN}=)/i.freeze
    BROKEN_UNQUOTED = /^#{CONDISP}.*;\sfilename=(#{TOKEN})/i.freeze
    MULTIPART_CONTENT_TYPE = /Content-Type: (.*)#{EOL}/ni.freeze
    MULTIPART_CONTENT_DISPOSITION = /Content-Disposition:.*\s+name="?([^\";]*)"?/ni.freeze
    MULTIPART_CONTENT_ID = /Content-ID:\s*([^#{EOL}]*)/ni.freeze

    HEADER_KV = /(?<k>[^:]+): (?<v>.*)/.freeze
    UNTIL_NEWLINE = /\A([^\n]*\n)/.freeze
    TERMINAL_CRLF = /\r\n$/.freeze


    BUFSIZE = 16384

    def self.parse(headers,body)
      self.new(headers,body).parse
    end

    def initialize(headers, body)
      @headers = headers
      @io = StringIO.new
      Array(body).each do |chunk|
        @io << chunk
      end
      @io.rewind
      @parts = Array.new
    end

    def parse
      return nil unless setup_parse

      @preamble = fast_forward_to_first_boundary

      loop do
        head, filename, content_type, name, body =
          get_current_head_and_filename_and_content_type_and_name_and_body

        # Save the rest.
        if i = @buf.index(rx)
          body << @buf.slice!(0, i)
          @buf.slice!(0, @boundary_size+2)

          @content_length = -1  if $1 == "--"
        end

        filename, data = get_data(filename, body, content_type, name, head)

        parsed_headers = head.split(EOL).each_with_object(Hash.new) do |line, hash|
          match = HEADER_KV.match(line)
          k = match[:k]
          v = match[:v]
          hash[k] = v
        end

        part = MultipartPart.new(data, parsed_headers, name: name, filename: filename)

        @parts << part

        # break if we're at the end of a buffer, but not if it is the end of a field
        break if (@buf.empty? && $1 != EOL) || @content_length == -1
      end

      @io.rewind

      [@preamble, @parts]
    end

    private
    def setup_parse
      unless (match = MULTIPART.match @headers['Content-Type'])
        return false
      end

      @boundary = "--#{match[1]}"

      @buf = ""

      @params = Rack::Utils::KeySpaceConstrainedParams.new

      @boundary_size = Rack::Utils.bytesize(@boundary) + EOL.size

      if @content_length = @headers['Content-Length']
        @content_length = @content_length.to_i
        @content_length -= @boundary_size
      end
      true
    end

    def full_boundary
      @boundary + EOL
    end

    def rx
      @rx ||= /(?:#{EOL})?#{Regexp.quote(@boundary)}(#{EOL}|--)/n
    end

    def fast_forward_to_first_boundary
      preamble = ''
      loop do
        content = @io.read(BUFSIZE)
        raise EOFError, "bad content body" unless content
        @buf << content

        while @buf.gsub!(UNTIL_NEWLINE, '')
          read_buffer = $1
          if read_buffer == full_boundary
            return preamble.gsub!(TERMINAL_CRLF,'')
          else
            preamble << read_buffer
          end
        end

        raise EOFError, "bad content body" if Rack::Utils.bytesize(@buf) >= BUFSIZE
      end
    end

    def get_current_head_and_filename_and_content_type_and_name_and_body
      head = nil
      body = ''
      filename = content_type = name = nil
      content = nil

      until head && @buf =~ rx
        if !head && i = @buf.index(EOL+EOL)
          head = @buf.slice!(0, i+2) # First \r\n

          @buf.slice!(0, 2)          # Second \r\n

          content_type = head[MULTIPART_CONTENT_TYPE, 1]
          name = head[MULTIPART_CONTENT_DISPOSITION, 1] || head[MULTIPART_CONTENT_ID, 1]
          name.strip!

          filename = get_filename(head)

          if filename
            body = Tempfile.new("RackMultipart")
            body.binmode if body.respond_to?(:binmode)
          end

          next
        end

        # Save the read body part.
        if head && (@boundary_size+4 < @buf.size)
          body << @buf.slice!(0, @buf.size - (@boundary_size+4))
        end

        content = @io.read(@content_length && BUFSIZE >= @content_length ? @content_length : BUFSIZE)
        raise EOFError, "bad content body"  if content.nil? || content.empty?

        @buf << content
        @content_length -= content.size if @content_length
      end

      [head, filename, content_type, name, body]
    end

    def get_filename(head)
      filename = nil
      if head =~ RFC2183
        filename = Hash[head.scan(DISPPARM)]['filename']
        filename = $1 if filename and filename =~ /^"(.*)"$/
      elsif head =~ BROKEN_QUOTED
        filename = $1
      elsif head =~ BROKEN_UNQUOTED
        filename = $1
      end

      if filename && filename.scan(/%.?.?/).all? { |s| s =~ /%[0-9a-fA-F]{2}/ }
        filename = Rack::Utils.unescape(filename)
      end
      if filename && filename !~ /\\[^\\"]/
        filename = filename.gsub(/\\(.)/, '\1')
      end
      filename
    end

    def get_data(filename, body, content_type, name, head)
      # filename is blank which means no file has been selected
      return nil if filename == ""

      # Take the basename of the upload's original filename.
      # This handles the full Windows paths given by Internet Explorer
      # (and perhaps other broken user agents) without affecting
      # those which give the lone filename.
      filename = filename.split(/[\/\\]/).last if filename

      # Rewind any IO bodies so the app can read them at its leisure
      body.rewind if  body.is_a?(IO)

      [filename, body]
    end
  end
end
