

module ApiResources
  class Instances
    include Praxis::ResourceDefinition

    media_type Instance
    version '1.0'

    #response_groups :premium
    #responses :instance_limit_reached
    #responses :pay_us_money

    use :authenticated

    routing do
      prefix '/clouds/:cloud_id/instances'
    end

    params do
      attribute :cloud_id, Integer, required: true
    end

    action :index do
      routing do
        get ''
      end
    end

    action :show do
      routing do
        get '/:id'
        get '/something/:id', name: :alternate
      end

      responses :other_response

      params do
        attribute :id #, Integer, required: true, min: 1
        attribute :junk, String, default: ''
        attribute :some_date, DateTime, default: DateTime.parse('2012-12-21')
      end
      payload do
        attribute :something, String
        attribute :optional, String, default: "not given"
      end
    end

    action :attach_file do
      routing do
        post '/:id/files'
      end

      params do
        attribute :id #, Integer, required: true, min: 1
      end

      payload Praxis::Multipart do
        key 'destination_path', String, required: true
        key 'file', String, required: true #FileUpload, required: true
      end
    end

    action :bulk_create do
      routing do
        post ''
      end

      payload Praxis::Multipart.of(key: Integer, value: Instance)

      #payload do
      #  attribute :instance, Hash.of(key:Integer), key_type: Integer do
      #    key 'something'
      #  end
      #end
    end

    #   # single file, super simple upload
    #   payload Multipart.of(FileUpload), count: 1
    #   request.payload

    #   # one single part, named :foobar, that is a filename thingy
    #   payload Multipart do
    #     attribute :foobar, FileUpload
    #   end

    #   payload Multipart.of(key_type: UUID, value_type: FileUploads)

    #   payload Multipart

    #   request.


    #   # single file, upload with other stuff
    #   payload do
    #     attribute :destination, String, required: true
    #     attribute :guts, FileUpload
    #   end

    #   # multiple files, unspecified name
    #   payload do
    #     attribute :destination, String, required: true
    #     attribute :**, MultipartHashyThing.of(value_type: FileUpload)
    #   end


    #   # bulk request, tons of mini sub request thingies
    #   payload_part  do
    #     attribute :id
    #     attribute :foo
    #   end

    #   # payload do
    #   #   part :destination, String
    #   #   part :fileupload, FileUpload
    #   # end

    #   payload.part.destination.
    # end

    # action :bulk_create do
    #   routing do
    #     post '/_bulk'
    #   end

    #   payload Instance
    #   multipart true

    # end

  end

end
