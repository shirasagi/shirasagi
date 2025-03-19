module Facility::Addon::Image
  module Model
    extend ActiveSupport::Concern
    extend SS::Translation
    include SS::Relation::File

    ACCEPTABLE_EXTS = %w(.gif .jpeg .jpg .png .webp).freeze

    included do
      belongs_to_file :image, accepts: ACCEPTABLE_EXTS
    end
  end
end
