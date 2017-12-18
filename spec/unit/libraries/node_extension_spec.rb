require 'spec_helper'

describe ::Chef::Node do
  let(:node) do
    ::ChefSpec::SoloRunner.new(platform: 'windows', version: '2016')
                          .converge('updatable-attributes')
                          .node
  end
  describe 'the method on_attribute_update do' do
    def register_block(on_init: true)
      node.on_attribute_update('foo', init_on_registration: on_init) do
        node.default['bar'] = node['foo'].to_i + 1
      end
    end

    it 'registers the block and call it on update of the target attribute' do
      register_block
      node.default['foo'] = 1
      expect(node['bar']).to be 2
      node.default['foo'] = 2
      expect(node['bar']).to be 3
    end

    it 'calls the block on init by default' do
      expect(node['bar']).to be nil
      register_block
      expect(node['bar']).to be 1
    end

    it 'does not call the block when init_on_registration is false' do
      expect(node['bar']).to be nil
      register_block(on_init: false)
      expect(node['bar']).to be nil
    end

    it 'does not call the block for non-registered attributes update' do
      expect(node['bar']).to be nil
      register_block(on_init: false)
      node.default['blah'] = 12
      expect(node['bar']).to be nil
    end
  end

  describe 'the method on_attributes_update do' do
    before { node.default['install'] }

    def register_block(on_init: true)
      node.on_attributes_update(%w[install hostname], %w[install domain], init_on_registration: on_init) do
        hostname = node['install']['hostname']
        domain = node['install']['domain']
        node.default['install']['fqdn'] = [hostname, domain].compact.join('.')
      end
    end

    it 'registers the block and call it on update of the target attributes' do
      register_block
      node.default['install']['hostname'] = 'foo'
      expect(node['install']['fqdn']).to eq 'foo'
      node.default['install']['domain'] = 'bar'
      expect(node['install']['fqdn']).to eq 'foo.bar'
    end

    it 'calls the block on init by default' do
      expect(node['install']['hostname']).to be nil
      expect(node['install']['domain']).to be nil
      register_block
      expect(node['install']['fqdn']).to eq ''
    end

    it 'does not call the block when init_on_registration is false' do
      expect(node['install']['hostname']).to be nil
      expect(node['install']['domain']).to be nil
      register_block(on_init: false)
      expect(node['install']['fqdn']).to be nil
    end

    it 'does not call the block for non-registered attributes update' do
      expect(node['install']['hostname']).to be nil
      expect(node['install']['domain']).to be nil
      register_block(on_init: false)
      expect(node['install']['fqdn']).to be nil
      node.default['blah'] = 12
      expect(node['install']['fqdn']).to be nil
    end
  end
end
