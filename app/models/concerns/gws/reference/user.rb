module Gws::Reference
  module User
    extend ActiveSupport::Concern
    extend SS::Reference::User

    included do
      belongs_to :user, class_name: "Gws::User"
    end
  end
end
