require 'spec_helper'

describe 'on_attribute_update' do
  subject(:node) { ::ChefSpec::SoloRunner.new(platform: 'windows', version: '2016').converge('updatable-attributes').node }
  before { node } # Ensure the libraries are loaded

  # This seems 
  it 'shoult not detect loop due to AutoVivification on different precedence level' do
    node.default['base']['delay'] = -1
    node.default['base']['value'] = nil
    node.on_attribute_update('base', 'delay') do
      node.force_default['base']['value'] = 37 + node['base']['delay'] if node['base']['delay'].positive?
    end
    node.default['base']['delay'] = 5
    expect(node['base']['value']).to be 42
  end
end
