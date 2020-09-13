require_relative 'default.rb'
require_relative 'update_dispatcher.rb'

class Chef
  # Add extension methods on Chef Node
  class Node
    def on_attribute_update(*path, init_on_registration: true, observe_parents: true, &block)
      path = path.first if path.is_a?(::Array) && path.one?
      on_attributes_update(path,
                           init_on_registration: init_on_registration,
                           observe_parents:      observe_parents,
                           &block)
    end

    def on_attributes_update(*paths, init_on_registration: true, observe_parents: true, &block)
      raise ::ArgumentError, 'no block given' if block.nil?
      paths = paths.map { |path| ::Kernel.Array(path) }
                   .each { |path| ::ChefUpdatableAttributes.validate_path!(path) }
      ::ChefUpdatableAttributes::UpdateDispatcher.register(self, *paths, observe_parents: observe_parents, &block)
      yield nil, nil, nil if init_on_registration
    end
  end
end
