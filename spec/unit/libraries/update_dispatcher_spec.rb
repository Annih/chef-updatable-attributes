require 'spec_helper'
require_relative '../../../libraries/update_dispatcher'

describe ::ChefUpdatableAttributes::UpdateDispatcher do
  subject(:dispatcher) { described_class.new(node) }

  let(:paths) { [%w[path], %w[another path], %w[yet another path]] }
  let(:handlers) { ::Array.new(2) { |i| ::Proc.new { raise "Handler#{i} called while not expected" } } }
  let(:node) { ::ChefSpec::SoloRunner.new(platform: 'windows', version: 2016).converge('updatable-attributes').node }

  describe '.register' do
    shared_examples 'common_registration_examples' do
      it 'calls #register for each given path' do
        expect(dispatcher).to receive(:register).with(paths[0]) { |&b| expect(b).to eq handlers[0] }.ordered
        expect(dispatcher).to receive(:register).with(paths[0]) { |&b| expect(b).to eq handlers[1] }.ordered
        expect(dispatcher).to receive(:register).with(paths[1]) { |&b| expect(b).to eq handlers[1] }.ordered

        described_class.register(node, paths[0], &handlers[0])
        described_class.register(node, paths[0], paths[1], &handlers[1])
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

      expect(handlers[0]).to receive(:call).once.with(:default, paths[0], 1).ordered
      expect(handlers[0]).to receive(:call).once.with(:override, paths[1], 2).ordered
      expect(handlers[1]).to receive(:call).once.with(:override, paths[1], 2).ordered

      node.write(:default, *paths[0], 1)
      node.write(:override, *paths[1], 2)
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

    it 'passes the path to the handler' do
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

    it 'passes the value to the handler' do
      allow(node).to receive(:read).with(*paths[0]).and_return('value_0_0', 'value_0_1', 'value_0_2', 'value_0_3')
      subject.register(paths[0], &handlers[0])

      expect(handlers[0]).to receive(:call).with(anything, anything, 'value_0_1').ordered
      expect(handlers[0]).to receive(:call).with(anything, anything, 'value_0_2').ordered
      expect(handlers[0]).to receive(:call).with(anything, anything, 'value_0_3').ordered

      subject.attribute_changed(:default, paths[0], 'value_0_1')
      subject.attribute_changed(:default, paths[0], 'value_0_2')
      subject.attribute_changed(:default, paths[0], 'value_0_3')
    end

    it 'raises UpdateLoop on notification loops' do
      allow(node).to receive(:read).with(*paths[0]).and_return('value_0_0', 'value_0_1')
      subject.register(paths[0]) { subject.attribute_changed(:default, paths[0], 'value_0_x') }

      expect { subject.attribute_changed(:default, paths[0], 1) }.to raise_error(described_class::UpdateLoop)
    end
  end
end
