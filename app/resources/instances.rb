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
        attribute :id
        attribute :junk, String, default: ''
        attribute :some_date, DateTime, default: DateTime.parse('2012-12-21')
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

      # response MultipartResponse.with(part_response: CreateResponse.with(type: Instance))

      # responses :bulk_create_response


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

      payload Praxis::Multipart do
        key 'destination_path', String, required: true
        key 'file', Attributor::FileUpload, required: true
      end

      #responses :default
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
