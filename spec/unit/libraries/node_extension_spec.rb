require 'spec_helper'

describe ::Chef::Node do
  subject(:node) { ::ChefSpec::SoloRunner.new(platform: 'windows', version: '2016').converge('updatable-attributes').node }
  let(:paths) { [['foo'], %w[foo bar], ['blah']] }
  let(:handlers) { ::Array.new(3) { ::Proc.new {} } }

  before { node } # Ensure the libraries are loaded

  describe '#on_attribute_update' do
    it 'registers the handler on the UpdateDispatcher' do
      expect(::ChefUpdatableAttributes::UpdateDispatcher).to receive(:register)
        .with(node, paths[0], anything, &handlers[0]).ordered
      expect(::ChefUpdatableAttributes::UpdateDispatcher).to receive(:register)
        .with(node, paths[1], anything, &handlers[1]).ordered
      expect(::ChefUpdatableAttributes::UpdateDispatcher).to receive(:register)
        .with(node, paths[2], anything, &handlers[2]).ordered

      subject.on_attribute_update(*paths[0], &handlers[0])
      subject.on_attribute_update(*paths[1], &handlers[1])
      subject.on_attribute_update(paths[2], &handlers[2]) # missing splat is on purpose
    end

    context 'when init_on_registration is true' do
      it 'calls the handler directly with nil values' do
        expect { |b| subject.on_attribute_update(*paths[0], init_on_registration: true, &b) }.to yield_with_args(nil, nil, nil)
      end
    end

    context 'when init_on_registration is false' do
      it 'does not call the handler' do
        expect { |b| subject.on_attribute_update(*paths[0], init_on_registration: false, &b) }.not_to yield_control
      end
    end

    it 'passes observe_parents to the registration call' do
      expect(::ChefUpdatableAttributes::UpdateDispatcher).to receive(:register)
        .with(node, paths[0], observe_parents: true, recursion: 0) { |&b| expect(b).to eq handlers[0] }.ordered
      expect(::ChefUpdatableAttributes::UpdateDispatcher).to receive(:register)
        .with(node, paths[1], observe_parents: true, recursion: 0) { |&b| expect(b).to eq handlers[1] }.ordered
      expect(::ChefUpdatableAttributes::UpdateDispatcher).to receive(:register)
        .with(node, paths[2], observe_parents: false, recursion: 0) { |&b| expect(b).to eq handlers[2] }.ordered

      subject.on_attribute_update(*paths[0], &handlers[0])
      subject.on_attribute_update(*paths[1], observe_parents: true, &handlers[1])
      subject.on_attribute_update(*paths[2], observe_parents: false, &handlers[2])
    end

    it 'passes recursion to the registration call' do
      expect(::ChefUpdatableAttributes::UpdateDispatcher).to receive(:register)
        .with(node, paths[0], observe_parents: true, recursion: 0) { |&b| expect(b).to eq handlers[0] }.ordered
      expect(::ChefUpdatableAttributes::UpdateDispatcher).to receive(:register)
        .with(node, paths[1], observe_parents: true, recursion: 1) { |&b| expect(b).to eq handlers[1] }.ordered
      expect(::ChefUpdatableAttributes::UpdateDispatcher).to receive(:register)
        .with(node, paths[2], observe_parents: true, recursion: 5) { |&b| expect(b).to eq handlers[2] }.ordered

      subject.on_attribute_update(*paths[0], &handlers[0])
      subject.on_attribute_update(*paths[1], recursion: 1, &handlers[1])
      subject.on_attribute_update(*paths[2], recursion: 5, &handlers[2])
    end
  end

  describe '#on_attributes_update' do
    it 'registers the handlers on the UpdateDispatcher' do
      expect(::ChefUpdatableAttributes::UpdateDispatcher).to receive(:register)
        .with(node, paths[0], anything, &handlers[0]).ordered
      expect(::ChefUpdatableAttributes::UpdateDispatcher).to receive(:register)
        .with(node, *paths, anything, &handlers[0]).ordered

      subject.on_attributes_update(paths[0], &handlers[0])
      subject.on_attributes_update(paths[0], paths[1], paths[2], &handlers[0])
    end

    context 'when init_on_registration is true' do
      it 'calls the handler directly with nil values' do
        expect { |b| subject.on_attributes_update(*paths, init_on_registration: true, &b) }.to yield_with_args(nil, nil, nil)
      end
    end

    context 'when init_on_registration is false' do
      it 'does not call the handler' do
        expect { |b| subject.on_attributes_update(*paths, init_on_registration: false, &b) }.not_to yield_control
      end
    end

    it 'passes observe_parents to the registration call' do
      expect(::ChefUpdatableAttributes::UpdateDispatcher).to receive(:register)
        .with(node, *paths, observe_parents: true, recursion: 0) { |&b| expect(b).to eq handlers[0] }.ordered
      expect(::ChefUpdatableAttributes::UpdateDispatcher).to receive(:register)
        .with(node, *paths, observe_parents: true, recursion: 0) { |&b| expect(b).to eq handlers[1] }.ordered
      expect(::ChefUpdatableAttributes::UpdateDispatcher).to receive(:register)
        .with(node, *paths, observe_parents: false, recursion: 0) { |&b| expect(b).to eq handlers[2] }.ordered

      subject.on_attributes_update(*paths, &handlers[0])
      subject.on_attributes_update(*paths, observe_parents: true, &handlers[1])
      subject.on_attributes_update(*paths, observe_parents: false, &handlers[2])
    end
  end
end
