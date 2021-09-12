require 'spec_helper'
require_relative '../../../libraries/update_dispatcher'

describe ::ChefUpdatableAttributes::UpdateDispatcher do
  PRECEDENCES = %i[default force_default normal override force_override automatic].freeze

  subject(:dispatcher) { described_class.new(node) }

  let(:paths) { [%w[path], %w[another path], %w[yet another path]] }
  let(:handlers) { ::Array.new(2) { |i| ::Proc.new { raise "Handler#{i} called while not expected" } } }
  let(:node) { ::ChefSpec::SoloRunner.new(platform: 'windows', version: 2016).converge('updatable-attributes').node }

  describe '.register' do
    shared_examples 'common_registration_examples' do
      it 'calls #register for each given path' do
        expect(dispatcher).to receive(:register).with(paths[0], any_args) { |&b| expect(b).to eq handlers[0] }.ordered
        expect(dispatcher).to receive(:register).with(paths[0], any_args) { |&b| expect(b).to eq handlers[1] }.ordered
        expect(dispatcher).to receive(:register).with(paths[1], any_args) { |&b| expect(b).to eq handlers[1] }.ordered

        described_class.register(node, paths[0], &handlers[0])
        described_class.register(node, paths[0], paths[1], &handlers[1])
      end

      it 'passes observe_parents to #register' do
        block_verifier = ::Proc.new { |&b| expect(b).to eq handlers[0] }
        expect(dispatcher).to receive(:register).with(paths[0], observe_parents: true, recursion: 0, &block_verifier).ordered
        expect(dispatcher).to receive(:register).with(paths[1], observe_parents: true, recursion: 0, &block_verifier).ordered
        expect(dispatcher).to receive(:register).with(paths[1], observe_parents: true, recursion: 0, &block_verifier).ordered
        expect(dispatcher).to receive(:register).with(paths[2], observe_parents: true, recursion: 0, &block_verifier).ordered
        expect(dispatcher).to receive(:register).with(paths[2], observe_parents: false, recursion: 0, &block_verifier).ordered
        expect(dispatcher).to receive(:register).with(paths[0], observe_parents: false, recursion: 0, &block_verifier).ordered

        described_class.register(node, paths[0], paths[1], &handlers[0])
        described_class.register(node, paths[1], paths[2], observe_parents: true, &handlers[0])
        described_class.register(node, paths[2], paths[0], observe_parents: false, &handlers[0])
      end

      it 'passes recursion to #register' do
        block_verifier = ::Proc.new { |&b| expect(b).to eq handlers[0] }
        expect(dispatcher).to receive(:register).with(paths[0], observe_parents: true, recursion: 0, &block_verifier).ordered
        expect(dispatcher).to receive(:register).with(paths[1], observe_parents: true, recursion: 0, &block_verifier).ordered
        expect(dispatcher).to receive(:register).with(paths[1], observe_parents: true, recursion: 1, &block_verifier).ordered
        expect(dispatcher).to receive(:register).with(paths[2], observe_parents: true, recursion: 1, &block_verifier).ordered
        expect(dispatcher).to receive(:register).with(paths[2], observe_parents: true, recursion: 5, &block_verifier).ordered
        expect(dispatcher).to receive(:register).with(paths[0], observe_parents: true, recursion: 5, &block_verifier).ordered

        described_class.register(node, paths[0], paths[1], &handlers[0])
        described_class.register(node, paths[1], paths[2], recursion: 1, &handlers[0])
        described_class.register(node, paths[2], paths[0], recursion: 5, &handlers[0])
      end
    end

    context 'when first called' do
      it "instanciates a new #{described_class}" do
        expect(described_class).to receive(:new).once.and_call_original
        described_class.register(node, paths[0], &handlers[0])
      end

      it 'registers the new instance as Chef Event Handler' do
        described_class.register(node, paths[0], &handlers[0])
        expect(node.run_context.events.subscribers.last).to be_a(described_class)
      end

      include_examples 'common_registration_examples'
    end

    context 'when already called' do
      before { allow(described_class).to receive(:new).and_return dispatcher }

      it "reuses registered #{described_class} instance" do
        expect(described_class).not_to receive(:new)

        described_class.register(node, paths[0], &handlers[0])
        expect(node.run_context.events.subscribers).to include dispatcher
      end

      include_examples 'common_registration_examples'
    end
  end

  describe '#register' do
    it 'raises an ::ArgumentError if no block is given' do
      expect { subject.register(paths[0]) }.to raise_error(::ArgumentError, /block/)
    end

    it 'registers the given block to attribute changes on the specified path' do
      subject.register(paths[0], &handlers[0])
      subject.register(paths[1], &handlers[0])
      subject.register(paths[1], &handlers[1])

      expect(handlers[0]).to receive(:call).once.with(:default, paths[0], 1, nil).ordered
      expect(handlers[0]).to receive(:call).once.with(:override, paths[1], 2, nil).ordered
      expect(handlers[1]).to receive(:call).once.with(:override, paths[1], 2, nil).ordered

      node.write(:default, *paths[0], 1)
      node.write(:override, *paths[1], 2)
    end

    context 'when observe_parents is true' do
      it 'also registers the given block for parent paths' do
        observed_path = %w[foo bar blah]
        subject.register(observed_path, observe_parents: true, &handlers[0])
        expect(handlers[0]).to receive(:call).with(:default, observed_path, 'original', nil)
        node.write(:default, *observed_path, 'original')

        # When writting a Hash at the parent level
        expect(handlers[0]).to receive(:call).with(:default, observed_path, 'updated', 'original')
        node.write(:default, *observed_path[0...2], observed_path[2] => 'updated')
        # When removed at the parent level
        expect(handlers[0]).to receive(:call).with(:default, observed_path, nil, 'updated')
        node.write(:default, *observed_path[0...2], {})

        # When writting a Hash at the parent parent level
        expect(handlers[0]).to receive(:call).with(:default, observed_path, 'reset', nil)
        node.write(:default, observed_path[0], observed_path[1] => { observed_path[2] => 'reset' })
        # When removed at the parent parent level
        expect(handlers[0]).to receive(:call).with(:default, observed_path, nil, 'reset')
        node.write(:default, observed_path[0], {})
      end
    end

    context 'when observe_parents is false' do
      it 'does not registers the given block for parent paths' do
        observed_path = %w[foo bar blah]
        subject.register(observed_path, observe_parents: false, &handlers[0])

        expect(handlers[0]).not_to receive(:call).with(any_args)
        1.upto(2) { |i| node.write(:default, observed_path[0...i], i) }
      end
    end
  end

  describe '#attribute_changed' do
    it 'calls subscribers of the given attribute path' do
      allow(node).to receive(:read).with(*paths[0]).and_return('value_0_0', 'value_0_1')
      subject.register(paths[0], &handlers[0])

      expect(handlers[0]).to receive(:call).once

      subject.attribute_changed(:normal, paths[0], 'value_0_1')
    end

    it 'does not call subscribers of another attribute path' do
      allow(node).to receive(:read).with(*paths[0]).and_return 'value_0_0'
      allow(node).to receive(:read).with(*paths[1]).and_return('value_1_0', 'value_1_1')
      subject.register(paths[0], &handlers[0])
      subject.register(paths[1], &handlers[1])

      expect(handlers[0]).not_to receive(:call)
      expect(handlers[1]).to receive(:call).once

      subject.attribute_changed(:normal, paths[1], 'value_1_1')
    end

    it 'does not call the subscriber if the compiled value is unchanged' do
      allow(node).to receive(:read).with(*paths[0]).and_return('value_0_0', 'value_0_0')
      subject.register(paths[0], &handlers[0])

      expect(handlers[0]).not_to receive(:call)

      subject.attribute_changed(:default, paths[0], 'value_0_0')
      subject.attribute_changed(:normal, paths[0], 'value_0_0')
      subject.attribute_changed(:automatic, paths[0], 'value_0_0')
    end

    it 'passes the precedence to the handler' do
      allow(node).to receive(:read).with(*paths[0]).and_return('value_0_0', 'value_0_1', 'value_0_2', 'value_0_3')
      subject.register(paths[0], &handlers[0])

      expect(handlers[0]).to receive(:call).with(:default, any_args).ordered
      expect(handlers[0]).to receive(:call).with(:normal, any_args).ordered
      expect(handlers[0]).to receive(:call).with(:automatic, any_args).ordered

      subject.attribute_changed(:default, paths[0], 'value_0_1')
      subject.attribute_changed(:normal, paths[0], 'value_0_2')
      subject.attribute_changed(:automatic, paths[0], 'value_0_3')
    end

    context 'when called with "observed" path' do
      it 'passes it to the handler' do
        allow(node).to receive(:read).with(*paths[0]).and_return('value_0_0', 'value_0_1')
        allow(node).to receive(:read).with(*paths[1]).and_return('value_1_0', 'value_1_1')
        allow(node).to receive(:read).with(*paths[2]).and_return('value_2_0', 'value_2_1')
        subject.register(paths[0], &handlers[0])
        subject.register(paths[1], &handlers[0])
        subject.register(paths[2], &handlers[0])

        expect(handlers[0]).to receive(:call).with(:default, paths[0], any_args).ordered
        expect(handlers[0]).to receive(:call).with(:default, paths[1], any_args).ordered
        expect(handlers[0]).to receive(:call).with(:default, paths[2], any_args).ordered

        subject.attribute_changed(:default, paths[0], 'value_0_1')
        subject.attribute_changed(:default, paths[1], 'value_1_1')
        subject.attribute_changed(:default, paths[2], 'value_2_1')
      end
    end

    context 'when called with parent path' do
      it 'passes the "observed" path to the handler' do
        allow(node).to receive(:read).with(*paths[1]).and_return('value_1_0', nil)
        allow(node).to receive(:read).with(paths[1][0]).and_return('value_1_0.0_0')
        subject.register(paths[1], &handlers[0])

        expect(handlers[0]).to receive(:call).with(anything, paths[1], any_args)

        subject.attribute_changed(:default, [paths[1][0]], 'value_1.0_1')
      end
    end

    it 'passes the new and old values to the handler' do
      allow(node).to receive(:read).with(*paths[0]).and_return('value_0_0', 'value_0_1', 'value_0_2', 'value_0_3')
      subject.register(paths[0], &handlers[0])

      expect(handlers[0]).to receive(:call).with(anything, anything, 'value_0_1', 'value_0_0').ordered
      expect(handlers[0]).to receive(:call).with(anything, anything, 'value_0_2', 'value_0_1').ordered
      expect(handlers[0]).to receive(:call).with(anything, anything, 'value_0_3', 'value_0_2').ordered

      subject.attribute_changed(:default, paths[0], 'value_0_1')
      subject.attribute_changed(:default, paths[0], 'value_0_2')
      subject.attribute_changed(:default, paths[0], 'value_0_3')
    end

    context 'when block raises an error' do
      # Added for https://github.com/Annih/chef-updatable-attributes/issues/5
      it 'properly clean the UpdateLoop detection system' do
        allow(node).to receive(:read).with(*paths[0]).and_return('a', 'b', 'c', 'd')
        subject.register(paths[0]) { |_p, _k, v| raise 'FakeError' if v }

        expect { subject.attribute_changed(:default, paths[0], true) }.to raise_error(/FakeError/)
        expect { subject.attribute_changed(:default, paths[0], false) }.not_to raise_error described_class::UpdateLoop
      end
    end

    context 'when there is recursion' do
      let(:recursor) { ::Proc.new { |p, k, v| node.write(p, k, v - 1) unless v.zero? } }

      it 'raises UpdateLoop if not allowed' do
        allow(node).to receive(:read).with(*paths[0]).and_return(nil, 1, 0)
        subject.register(paths[0], &recursor)

        expect { subject.attribute_changed(:default, paths[0], 1) }.to raise_error(described_class::UpdateLoop)
      end

      it 'does not raise if allowed' do
        allow(node).to receive(:read).with(*paths[0]).and_return(nil, 1, 0)
        subject.register(paths[0], recursion: 2, &recursor)

        expect { subject.attribute_changed(:default, paths[0], 2) }.not_to raise_error
      end
    end
  end
end
