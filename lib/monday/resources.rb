# frozen_string_literal: true

Dir[File.join(__dir__, "resources", "*.rb")].sort.each { |file| require file }

module Monday
  # Encapsulates all available resources and includes them in the client.
  module Resources
    def self.initialize(client)
      constants.each do |constant|
        resource_class = const_get(constant)
        resource_name = constant.to_s.gsub(/([a-z\d])([A-Z])/, '\1_\2').downcase
        client.instance_variable_set("@#{resource_name}", resource_class.new(client))
        define_resource_accessor(client, resource_name) unless client.class.method_defined?(resource_name)
      end
    end

    def self.define_resource_accessor(client, resource_name)
      client.class.class_eval do
        attr_reader resource_name
      end
    end
  end
end
