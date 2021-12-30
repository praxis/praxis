require 'spec_helper'

describe Praxis::Bootloader do
  let(:application) do
    instance_double('Praxis::Application', config: 'config', root: 'root', plugins: {}, file_layout: {})
  end

  subject(:bootloader) { Praxis::Bootloader.new(application) }

  context 'attributes' do
    its(:application) { should be(application) }
    it 'stages' do
      init_stages = %i[environment plugins initializers lib design app routing warn_unloaded_files]
      expect(bootloader.stages.map { |s| s.name }).to eq(init_stages)
    end
    its(:config) { should be(application.config) }
    its(:root) { should be(application.root) }
  end

  context '.run' do
    it 'should call setup and run for all the stages' do
      bootloader.stages.each do |s|
        expect(s).to receive(:setup!).once
        expect(s).to receive(:run).once
      end
      bootloader.run
    end
  end
  context '.delete_stage' do
    it 'delete valid stage' do
      bootloader.delete_stage(:app)
      expect(bootloader.stages.include?(:app)).to be(false)
    end

    it 'raise errors when deleting invalid stage' do
      expect { bootloader.delete_stage(:unexistent_stage) }.to raise_error(Praxis::Exceptions::StageNotFound)
    end
  end

  context '.before' do
    it 'run before block of first element in stage_path' do
      stage = bootloader.stages.first
      allow(stage).to receive(:before).and_return('before!')
      expect(bootloader.before(stage.name)).to eq('before!')
    end

    it 'raises when given an invalid stage name' do
      expect do
        bootloader.before('nope!')
      end.to raise_error(Praxis::Exceptions::StageNotFound, /Error running a before block for stage nope!/)
    end
  end

  context '.after' do
    it 'run before block of first element in stage_path' do
      stage = bootloader.stages.first
      allow(stage).to receive(:after).and_return('after!')
      expect(bootloader.after(stage.name)).to eq('after!')
    end

    it 'raises when given an invalid stage name' do
      expect do
        bootloader.after('nope!')
      end.to raise_error(Praxis::Exceptions::StageNotFound, /Error running an after block for stage nope!/)
    end
  end

  context '.use' do
    let(:plugin) do
      Class.new(Praxis::Plugin) do
        def config_key
          :foo
        end
      end
    end

    it 'plugin add to application' do
      bootloader.use(plugin)
      expect(bootloader.application.plugins[:foo].class).to be(plugin)
    end

    it 'complains if a plugin with same name already registered' do
      bootloader.use(plugin)
      expect do
        bootloader.use(plugin)
      end.to raise_error(/another plugin (.*) is already registered with key: foo/)
    end
    context 'defaults config_key' do
      let(:plugin_two) do
        Class.new(Praxis::Plugin) do
          def self.name
            'Two' # Need this to avoid creating a true named class.
          end
        end
      end

      it 'to the class name' do
        bootloader.use(plugin_two)
        expect(bootloader.application.plugins[:two].class).to be(plugin_two)
      end

      it 'but raises if class is anonymous' do
        plugin_anon = Class.new(Praxis::Plugin) {}
        expect do
          bootloader.use(plugin_anon)
        end.to raise_error(/It does not have a config_key defined, and its class does not have a name/)
      end
    end
  end
end
