module Cms::Addon::Transaction
  module Command
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      field :command, type: String
      permit_params :command
    end
  end
end
