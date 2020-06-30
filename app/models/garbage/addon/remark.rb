module Garbage::Addon
  module Remark
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      field :remark_id, type: Integer
      field :attention, type: String

      permit_params :remark_id, :attention
    end
  end
end