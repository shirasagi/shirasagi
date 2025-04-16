module Cms::Addon::Transaction
  module Filename
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      field :filenames, type: SS::Extensions::Lines
      permit_params :filenames
    end
  end
end
