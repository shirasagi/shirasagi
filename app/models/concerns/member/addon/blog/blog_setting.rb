module Member::Addon::Blog
  module BlogSetting
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      field :page_limit, type: Integer, default: 3
      validates :page_limit, numericality: { only_integer: true, greater_than: 0, less_than_or_equal_to: 100 }
      permit_params :page_limit
    end
  end
end
