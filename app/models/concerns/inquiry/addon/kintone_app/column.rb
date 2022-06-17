module Inquiry::Addon
  module KintoneApp::Column
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      field :kintone_field_code, type: String
      permit_params :kintone_field_code
    end
  end
end
