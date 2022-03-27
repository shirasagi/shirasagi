module Article::Addon
  module MapSearch
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      field :map_search_options, type: Article::Extensions::MapSearchOptions, default: []
      permit_params map_search_options: [:name, :values]
    end
  end
end
