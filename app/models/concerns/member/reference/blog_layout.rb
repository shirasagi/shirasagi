module Member::Reference
  module BlogLayout
    extend ActiveSupport::Concern
    extend SS::Translation

    included do
      belongs_to :layout, class_name: "Member::BlogLayout"
      permit_params :layout_id

      validates :layout_id, presence: true
    end
  end
end
