module Facility::Addon::Image
  module Model
    extend ActiveSupport::Concern
    extend SS::Translation
    include SS::Relation::File

    included do
      belongs_to_file :image, accepts: SS::File::IMAGE_FILE_EXTENSIONS
    end
  end
end
