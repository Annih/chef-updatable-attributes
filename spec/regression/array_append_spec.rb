require 'spec_helper'

# Added for https://github.com/Annih/chef-updatable-attributes/issues/7
describe 'on_attribute_update' do
  subject(:node) { ::ChefSpec::SoloRunner.new(platform: 'windows', version: '2016').converge('updatable-attributes').node }
  let(:changes) { [] }

  before do
    # Ensure the libraries are loaded & prepare some attribues
    node.default['array'] = []
    node.on_attribute_update('array', init_on_registration: false) { |*v| changes << v }
  end

  it 'detects Array updates via push' do
    node.default['array'].push 1
    node.default['array'].push 2
    node.default['array'].push 3, 4, 5
    expect(changes).to be_an(::Array)
    expect(changes.size).to eq 3
    expect(node.default['array']).to eq [1, 2, 3, 4, 5]
  end

  it 'detects Array updates via <<' do
    node.default['array'] << 1
    node.default['array'] << 2
    node.default['array'] << 3
    expect(changes).to be_an(::Array)
    expect(changes.size).to eq 3
  end

  # This is not an Array mutator, but let's test it anyway :)
  it 'detects Array updates via +=' do
    node.default['array'] += [1]
    node.default['array'] += [1]
    node.default['array'] += [3]
    expect(changes).to be_an(::Array)
    expect(changes.size).to eq 3
  end
end
