module ChefUpdatableAttributes
  # Dispatch attribute update
  class UpdateDispatcher < ::Chef::EventDispatch::Base
    class UpdateLoop < ::RuntimeError; end

    # Holds attribute update subscription info
    class Subscription
      attr_reader :path, :callback

      def initialize(observed_path, &callback)
        @path = observed_path.dup.freeze
        @callback = callback
      end

      def source_location
        @callback.source_location
      end

      def notify(precedence, new_value)
        @callback.call(precedence, @path, new_value)
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

    def attribute_changed(precedence, path, value)
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
        subscription.notify(precedence, value)
        @stack.delete(location)
      end
    end

    def register(path, &block)
      raise ::ArgumentError, 'no block given' if block.nil?

      path = ::Kernel.Array(path)
      subscription = Subscription.new(path, &block)

      @subscriptions[path] << subscription

      subscription
    end

    def self.register(node, *paths, &block)
      dispatcher = node.run_context.events.subscribers.find { |s| s.is_a? UpdateDispatcher }
      dispatcher ||= new(node)
      paths.each { |p| dispatcher.register(p, &block) }
    end
  end
end
