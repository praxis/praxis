module ApiResources
  class Instances
    include Praxis::ResourceDefinition

    media_type Instance
    version '1.0'

    #response_groups :premium
    #responses :instance_limit_reached
    #responses :pay_us_money
    #response :create, location: /instances/

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

      response_content_type = self.resource_definition.media_type.identifier + ";type=collection"
      params do
        attribute :response_content_type, String, default: response_content_type
      end
      headers do
        # BOTH ARE EQUIVALENT
        #key "FOO", String, required: true
        header "FOO", /bar/
      end

      response :ok, media_type: response_content_type
    end

    action :show do
      routing do
        get '/:id'
        get '/something/:id', name: :alternate
      end

      response :ok

      params do
        attribute :id
        attribute :junk, String, default: ''
        attribute :some_date, DateTime, default: DateTime.parse('2012-12-21')
        attribute :fail_filter, Attributor::Boolean, default: false
      end
      payload do
        attribute :something, String
        attribute :optional, String, default: "not given"
      end
    end


    action :bulk_create do
      routing do
        post ''
      end

      payload Praxis::Multipart.of(key: Integer, value: Instance)

      # Using a hash param for parts
      response :bulk_response ,
                parts: {
                  like: :created,
                  location: /\/instances\//
                }

# Using a block for parts to defin a sub-request
#     sub_request = proc do
#                     status 201
#                     media_type Instance
#                     headers ['X-Foo','X-Bar']
#                   end
#     response :bulk_response, parts: sub_request


      # multi 200, H1
      # parts_as :resp1

      # part_type do
      #   201
      #   h Location ~= /asdfa/
      # end

      # part 'dest_dir' do

      # end
      # part 'file' do
      #   mt binary
      # end
    end

    #action :get_user_data do
    #  response :get_user_data do
    #    media_type: UserData
    #  end
    #end

    action :attach_file do
      routing do
        post '/:id/files'
      end

      params do
        attribute :id
      end

      payload Praxis::Multipart, allow_extra: true do
        key 'destination_path', String, required: true
        key 'file', Attributor::FileUpload, required: false
        extra 'options'
      end

      response :ok, media_type: 'application/json'
    end


    # OTHER USAGES:
    #   note: these are all hypothetical, pending, brainstorming usages.

    # given: single file, super simple upload, with count constraint
    # result: only one part is accepted
    # example:
    #   payload Praxis::Multipart.of(FileUpload), count: 1

    # given: multiple file uploads
    # example:
    #   payload Praxis::Multipart.of(key: UUID, value: Attributor::FileUpload)

    # given: any untyped multipart request body
    # example:
    #  payload Praxis::Multipart

    # given: single known key, plus multiple uploaded files which can take any name
    # result: multiple files collected into a single Hash.of(value: FileUpload)
    # example:
    #   payload Praxis::Multipart do
    #     key 'destination', String, required: true
    #     splat 'remaining', Hash.of(value: FileUpload)
    #   end

    # given: single known key, plus multiple uploaded files which can take any name
    # result: file parts coerced to FileUpload
    # example:
    #   payload Praxis::Multipart do
    #     key 'destination', String, required: true
    #     other_keys FileUpload
    #   end

    # given: single known key, plus multiple uploaded files, with names like 'file-'
    # result: file parts coerced to FileUpload
    # example:
    #   payload Praxis::Multipart do
    #     key 'destination', String, required: true
    #     match /file-.+/, FileUpload
    #   end

  end

end
