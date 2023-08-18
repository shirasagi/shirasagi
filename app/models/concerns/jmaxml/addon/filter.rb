module Jmaxml::Addon::Filter
  extend ActiveSupport::Concern
  extend SS::Addon

  included do
    embeds_many :filters, class_name: "Jmaxml::Filter"
  end
end
