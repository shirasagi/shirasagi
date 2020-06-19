module Guide::Addon
  module GuideList
    extend SS::Addon
    extend ActiveSupport::Concern
    include Cms::Addon::List::Model

    included do
      field :guide_index_html, type: String
      field :guide_html, type: String
      field :guide_url_fragment, type: String

      permit_params :guide_index_html, :guide_html, :guide_url_fragment
    end
  end
end
