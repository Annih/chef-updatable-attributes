require 'chef/node/mixin/immutablize_array'
require 'chef/node/mixin/state_tracking'

module ChefUpdatableAttributes
  # Patch ::Chef::Node::AttrArray to fix state tracking
  # See https://github.com/chef/chef/issues/13995
  module NodeAttrArrayStateTrackingExtension
    include ::Chef::Node::Mixin::StateTracking

    MUTATOR_METHODS = Chef::Node::Mixin::ImmutablizeArray::DISALLOWED_MUTATOR_METHODS

    # For all of the methods that may mutate an Array, we override them to
    # also track the state and trigger attribute_changed event.
    MUTATOR_METHODS.each do |mutator|
      define_method(mutator) do |*args, &block|
        ret = super(*args, &block)
        send_attribute_changed_event(__path__, self)
        ret
      end
    end

    # TODO: prepend conditionnally based on Chef::VERSION once issue fixed upstream
    # See https://github.com/chef/chef/pull/13996
    ::Chef::Node::AttrArray.prepend self
  end
end
