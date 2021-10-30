# override Mongoid::Traversable.get_discriminator_mapping
# 一見奇妙だけど https://github.com/mongodb/mongoid/blob/7.3-stable/lib/mongoid/traversable.rb#L116-L118 が奇妙なので、こうするよりない。
module Cms::Model::NodeDiscriminatorRetrieval
  extend ActiveSupport::Concern

  included do
    self.discriminator_key = "route"

    class << self
      alias_method :get_discriminator_mapping_without_shirasagi, :get_discriminator_mapping

      def get_discriminator_mapping(type)
        camelized = type.sub("/", "/node/").camelize

        # Check if the class exists
        begin
          camelized.constantize
        rescue NameError
          # return self if Rails.env.development?
          raise Mongoid::Errors::UnknownModel.new(camelized, type)
        end
      end
    end
  end
end
