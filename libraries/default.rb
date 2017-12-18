# Provide helpers for Updatable Attributes
module ChefUpdatableAttributes
  KEY_TYPES = [::String, ::Symbol, ::Numeric].freeze unless constants.include?(:KEY_TYPES)

  module_function

  def valid_path?(path)
    path.is_a?(::Array) && path.all? { |key| KEY_TYPES.any? { |type| key.is_a?(type) } }
  end

  def validate_path!(path)
    raise ::ArgumentError, <<~MESSAGE unless valid_path?(path)
      invalid Attribute's path

      A valid Attribute's path should be an Array of #{KEY_TYPES.join(' or ')}.
      You passed: '#{path}'.
    MESSAGE
  end
end
