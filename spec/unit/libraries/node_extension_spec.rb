require 'spec_helper'

describe ::Chef::Node do
  let(:node) do
    ::ChefSpec::SoloRunner.new(platform: 'windows', version: '2016')
                          .converge('updatable-attributes')
                          .node
  end
  describe 'the method on_attribute_update do' do
    it 'registers the block and call it on update of the target attribute' do
      node.on_attribute_update 'foo' do
        node.default['bar'] = node['foo'].to_i + 1
      end
      node.default['foo'] = 1
      expect(node['bar']).to be 2
      node.default['foo'] = 2
      expect(node['bar']).to be 3
    end

    it 'calls the block on init by default' do
      expect(node['bar']).to be nil
      node.on_attribute_update 'foo' do
        node.default['bar'] = node['foo'].to_i + 1
      end
      expect(node['bar']).to be 1
    end

    it 'does not call the block when init_on_registration is false' do
      expect(node['bar']).to be nil
      node.on_attribute_update 'foo', init_on_registration: false do
        node.default['bar'] = node['foo'].to_i + 1
      end
      expect(node['bar']).to be nil
    end

    it 'does not call the block for non-registered attributes update' do
      expect(node['bar']).to be nil
      node.on_attribute_update 'foo', init_on_registration: false do
        node.default['bar'] = node['foo'].to_i + 1
      end
      node.default['blah'] = 12
      expect(node['bar']).to be nil
    end
  end

  describe 'the method on_attribute_updates do' do
    it 'registers the block and call it on update of the target attributes' do
      node.on_attributes_update 'host_name', 'domain_name' do
        node.default['fqdn_value'] = [node['host_name'], node['domain_name']].compact.join('.')
      end
      node.default['host_name'] = 'foo'
      expect(node['fqdn_value']).to eq 'foo'
      node.default['domain_name'] = 'bar'
      expect(node['fqdn_value']).to eq 'foo.bar'
    end

    it 'calls the block on init by default' do
      expect(node['host_name']).to be nil
      expect(node['domain_name']).to be nil
      node.on_attributes_update 'host_name', 'domain_name' do
        node.default['fqdn_value'] = [node['host_name'], node['domain_name']].compact.join('.')
      end
      expect(node['fqdn_value']).to eq ''
    end

    it 'does not call the block when init_on_registration is false' do
      expect(node['host_name']).to be nil
      expect(node['domain_name']).to be nil
      node.on_attributes_update 'host_name', 'domain_name', init_on_registration: false do
        node.default['fqdn_value'] = [node['host_name'], node['domain_name']].compact.join('.')
      end
      expect(node['fqdn_value']).to be nil
    end

    it 'does not call the block for non-registered attributes update' do
      expect(node['host_name']).to be nil
      expect(node['domain_name']).to be nil
      node.on_attributes_update 'host_name', 'domain_name', init_on_registration: false do
        node.default['fqdn_value'] = [node['host_name'], node['domain_name']].compact.join('.')
      end
      expect(node['fqdn_value']).to be nil
      node.default['blah'] = 12
      expect(node['fqdn_value']).to be nil
    end
  end
end
