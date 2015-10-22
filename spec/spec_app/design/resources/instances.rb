module ApiResources
  class Instances
    include Praxis::ResourceDefinition

    media_type Instance
    version '1.0'

    # :show action is the canonical path for this resource.
    # Note that the following is redundant, since :show is the default canonical path if none is defined.
    canonical_path :show

    prefix '/clouds/:cloud_id/instances'

    trait :authenticated

    action_defaults do
      requires_ability :read

      params do
        attribute :cloud_id, Integer, required: true, min: 0
      end
    end

    action :index do
      routing do
        get ''
      end

      headers do
        # BOTH ARE EQUIVALENT
        #key "FOO", String, required: true
        header "FOO", /bar/
        key 'Account-Id', Integer, required: false, min: 0
      end

      params do
        attribute :response_content_type, String, default: 'application/vnd.acme.instance;type=collection'
      end


      response :ok, Praxis::Collection.of(Instance)
    end

    action :show do
      routing do
        get '/:id'
        get '/something/:id', name: :alternate
      end

      response :ok, media_type: 'application/json'
      response :unauthorized

      params do
        attribute :id, required: true
        attribute :junk, String, default: ''
        attribute :some_date, DateTime, default: DateTime.parse('2012-12-21')
        attribute :fail_filter, Attributor::Boolean, default: false
        attribute :create_identity_map, Attributor::Boolean, default: false
      end

      payload required: false do
        attribute :something, String
        attribute :optional, String, default: "not given"
      end
    end


    action :bulk_create do
      routing do
        post ''
      end

      payload Praxis::Types::MultipartArray do
        name_type Integer
        payload_type Instance
      end

      response :multipart_ok, Praxis::Types::MultipartArray do
        name_type Integer

        part /\d+/ do
          header 'Status', '201'
          header 'Content-Type', /^#{Instance.identifier}/
          header 'Location', Attributor::URI,
            example: proc { |part| ApiResources::Instances.to_href(cloud_id: part[:value].cloud_id, id: part[:value].id) }

          payload Hash do
            attribute :key, Integer, required: true
            attribute :value, Hash, required: true, reference: Instance do
              attribute :id
              attribute :name
            end
          end

        end
      end


      # Using a hash param for parts
      #response :multipart_ok, parts: {
      #  like: :created,
      #  location: /\/instances\//
      #}

      # Using a block for parts to defin a sub-request
      #     sub_request = proc do
      #                     status 201
      #                     media_type Instance
      #                     headers ['X-Foo','X-Bar']
      #                   end
      #     response :bulk_response, parts: sub_request
    end

    action :attach_file do
      routing do
        post '/:id/files'
      end

      params do
        attribute :id
      end

      # TODO: move to something else when Multipart is fully deprecated
      silence_warnings do
        payload Praxis::Multipart, allow_extra: true do
          key 'destination_path', String, required: true
          key 'file', Attributor::FileUpload, required: false
          extra 'options'
        end
      end

      response :ok, media_type: 'application/json'
      response :validation_error # TODO: include this by default, or rethink.
    end

    action :terminate do
      routing do
        any '/:id/terminate'
      end

      requires_ability :terminate

      params do
        attribute :id
      end

      payload do
        attribute :when, DateTime
      end

      response :ok, media_type: 'application/json'
    end

    action :stop do
      routing do
        post '/:id/stop'
      end
      requires_ability :stop

      params do
        attribute :id
      end


      response :ok, media_type: 'application/json'
    end

    action :update do
      routing do
        patch '/:id'
      end

      params do
        attribute :id, required: true
      end

      payload do
        attribute :name, regexp: /.*/
        attribute :root_volume
      end

      response :ok
    end


    action :exceptional do
      routing do
        prefix '//clouds/:cloud_id/otherinstances'
        get '/_action/*', except: '*/_action/exceptional'
      end
      params do
        attribute :splat, Attributor::Collection.of(String), required: true
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
