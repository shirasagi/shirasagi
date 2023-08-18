module Sys::Addon
  module EnvironmentSetting
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      field :keys, type: SS::Extensions::Words
      permit_params :keys
    end
  end
end
