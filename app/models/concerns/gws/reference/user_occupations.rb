module Gws::Reference
  module UserOccupations
    extend ActiveSupport::Concern
    extend SS::Translation
    include SS::Model::Reference::UserOccupations

    included do
      embeds_ids :occupations, class_name: "Gws::UserOccupation"
    end
  end
end
