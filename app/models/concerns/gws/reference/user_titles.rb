module Gws::Reference
  module UserTitles
    extend ActiveSupport::Concern
    extend SS::Translation
    include SS::Model::Reference::UserTitles

    included do
      embeds_ids :titles, class_name: "Gws::UserTitle"
    end
  end
end
