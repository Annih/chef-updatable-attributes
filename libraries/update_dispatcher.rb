module ChefUpdatableAttributes
  # Dispatch attribute update
  class UpdateDispatcher < ::Chef::EventDispatch::Base
    class UpdateLoop < ::RuntimeError; end

    # Holds attribute update subscription info
    class Subscription
      attr_reader :path, :callback, :attribute_value

      def initialize(observed_path, value = nil, &callback)
        @attribute_value = value
        @path = observed_path.dup.freeze
        @callback = callback
      end

      def source_location
        @callback.source_location
      end

      def notify(precedence, new_value)
        previous_value = @attribute_value

        return false if new_value == previous_value

        @attribute_value = new_value
        @callback.call(precedence, @path, new_value, previous_value)

        true
      end
    end

    def initialize(node, setup: true)
      super()
      @node = node
      @stack = ::Hash.new
      @subscriptions = ::Hash.new { |h, k| h[k] = [] }

      setup_event_handler if setup
    end

    def setup_event_handler
      @node.run_context.events.register(self)
    end

    def attribute_changed(precedence, path, _value)
      # Return to avoid auto-vivication of the subscriptions hash
      return unless @subscriptions.key?(path)

      @subscriptions[path].each do |subscription|
        location = subscription.source_location
        raise UpdateLoop, <<~MESSAGE if @stack.key?(location)
          a loop has been detected during Attribute update!

          Multiple notifications of the block defined at #{location.join(':')}.
          Here is the current notification stack:
          #{@stack}
        MESSAGE

        @stack[location] = path
        subscription.notify(precedence, @node.read(*subscription.path))
        @stack.delete(location)
      end
    end

    def register(path, observe_parents: true, &block)
      raise ::ArgumentError, 'no block given' if block.nil?

      path = ::Kernel.Array(path)
      subscription = Subscription.new(path, @node.read(*path), &block)

      key_lengths = observe_parents ? (1..path.size) : [path.size]
      key_lengths.each { |length| @subscriptions[path[0...length]] << subscription }

      subscription
    end

    def self.register(node, *paths, observe_parents: true, &block)
      dispatcher = node.run_context.events.subscribers.find { |s| s.is_a? UpdateDispatcher }
      dispatcher ||= new(node)
      paths.each { |p| dispatcher.register(p, observe_parents: observe_parents, &block) }
    end
  end
end
