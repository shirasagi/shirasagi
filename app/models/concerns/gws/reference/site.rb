module Gws::Reference
  module Site
    extend ActiveSupport::Concern
    extend SS::Reference::User

    included do
      belongs_to :site, class_name: "Gws::Group"
    end
  end
end
