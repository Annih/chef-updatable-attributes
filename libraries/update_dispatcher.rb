module ChefUpdatableAttributes
  # Dispatch attribute update
  class UpdateDispatcher < ::Chef::EventDispatch::Base
    class UpdateLoop < ::RuntimeError; end

    # Holds attribute update subscription info
    class Subscription
      attr_reader :path, :callback, :attribute_value, :max_depth, :current_depth

      def initialize(observed_path, value = nil, recursion = 0, &callback)
        @attribute_value = value
        @path = observed_path.dup.freeze
        @callback = callback
        @max_depth = recursion
        @current_depth = 0
      end

      def source_location
        @callback.source_location
      end

      def notify?(new_value)
        new_value != @attribute_value
      end

      def notify(precedence, new_value)
        previous_value = @attribute_value
        @current_depth += 1
        @attribute_value = new_value
        @callback.call(precedence, @path, new_value, previous_value)

        true
      ensure
        @current_depth -= 1
      end
    end

    def initialize(node, setup: true)
      super()
      @node = node
      @stack = []
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
        new_value = @node.read(*subscription.path)
        next unless subscription.notify?(new_value)

        location = subscription.source_location
        @stack << "#{location} with (#{precedence.inspect}, #{path.inspect}, #{value.inspect})"

        raise UpdateLoop, <<~MESSAGE if subscription.current_depth > subscription.max_depth
          a loop has been detected during Attribute update!

          Multiple notifications of the block defined at #{location.join(':')}.
          Here is the current notification stack:
          #{@stack.join("\n")}
        MESSAGE

        subscription.notify(precedence, new_value)
        @stack.pop
      end
    end

    def register(path, observe_parents: true, recursion: 0, &block)
      raise ::ArgumentError, 'no block given' if block.nil?

      path = ::Kernel.Array(path)
      subscription = Subscription.new(path, @node.read(*path), recursion, &block)

      key_lengths = observe_parents ? (1..path.size) : [path.size]
      key_lengths.each { |length| @subscriptions[path[0...length]] << subscription }

      subscription
    end

    def self.register(node, *paths, observe_parents: true, recursion: 0, &block)
      dispatcher = node.run_context.events.subscribers.find { |s| s.is_a? UpdateDispatcher }
      dispatcher ||= new(node)
      paths.each { |p| dispatcher.register(p, observe_parents: observe_parents, recursion: recursion, &block) }
    end
  end
end
