module Member::Reference
  module Blog
    extend ActiveSupport::Concern
    extend SS::Translation

    included do
      field :blog_id, type: Integer
      belongs_to :blog, class_name: "Member::Blog"
      permit_params :blog_id
    end
  end
end
