require_relative 'default'
require_relative 'update_dispatcher'

class Chef
  # Add extension methods on Chef Node
  class Node
    def on_attribute_update(*path, init_on_registration: true, observe_parents: true, recursion: 0, &block)
      path = path.first if path.is_a?(::Array) && path.one?
      on_attributes_update(path,
                           init_on_registration: init_on_registration,
                           observe_parents:      observe_parents,
                           recursion:            recursion,
                           &block)
    end

    def on_attributes_update(*paths, init_on_registration: true, observe_parents: true, recursion: 0, &block)
      raise ::ArgumentError, 'no block given' if block.nil?

      paths = paths.map { |path| ::Kernel.Array(path) }
                   .each { |path| ::ChefUpdatableAttributes.validate_path!(path) }
      ::ChefUpdatableAttributes::UpdateDispatcher.register(self,
                                                           *paths,
                                                           observe_parents: observe_parents,
                                                           recursion:       recursion,
                                                           &block)
      yield nil, nil, nil if init_on_registration
    end
  end
end
