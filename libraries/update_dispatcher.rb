module ChefUpdatableAttributes
  # Dispatch attribute update
  class UpdateDispatcher < ::Chef::EventDispatch::Base
    class UpdateLoop < ::RuntimeError; end

    def initialize
      super
      @stack = ::Hash.new
      @subscribers = ::Hash.new { |h, k| h[k] = [] }
    end

    def attribute_changed(precedence, path, value)
      # Return to avoid auto-vivication of the subscribers hash
      return unless @subscribers.key?(path)
      @subscribers[path].each do |block|
        location = block.source_location
        raise UpdateLoop, <<~MESSAGE if @stack.key?(location)
          a loop has been detected during Attribute update!

          Multiple notifications of the block defined at #{location.join(':')}.
          Here is the current notification stack:
          #{@stack}
        MESSAGE

        @stack[location] = path
        block.call(precedence, path, value)
        @stack.delete(location)
      end
    end

    def register(path, &block)
      raise ::ArgumentError, 'no block given' if block.nil?
      @subscribers[Array(path)] << block
    end

    def self.register(*paths, &block)
      dispatcher = ::Chef.node.run_context.events.subscribers.find { |s| s.is_a? UpdateDispatcher }
      dispatcher ||= new.tap { |instance| ::Chef.node.run_context.events.register(instance) }
      paths.each { |p| dispatcher.register(p, &block) }
    end
  end
end
