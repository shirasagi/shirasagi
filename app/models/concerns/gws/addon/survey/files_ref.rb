module Gws::Addon::Survey::FilesRef
  extend ActiveSupport::Concern
  extend SS::Addon

  included do
    has_many :files, class_name: 'Gws::Survey::File', dependent: :destroy, inverse_of: :form
  end
end
