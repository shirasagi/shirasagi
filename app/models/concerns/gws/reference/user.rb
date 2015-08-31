module Gws::Reference
  module User
    extend ActiveSupport::Concern

    included do
      belongs_to :user, class_name: "Gws::User"
    end
  end
end
