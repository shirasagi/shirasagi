module Gws::Addon::Questionnaire::FilesRef
  extend ActiveSupport::Concern
  extend SS::Addon

  included do
    has_many :files, class_name: 'Gws::Questionnaire::File', dependent: :destroy, inverse_of: :form
  end
end
