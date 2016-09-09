module Multilingual::Addon
  module Part
    extend ActiveSupport::Concern
    extend SS::Addon
    include Multilingual::Addon::Content

    included do
      foreign_field :html
    end

    def content_class
      Cms::Part
    end

    def content_name
      "part"
    end
  end
end
