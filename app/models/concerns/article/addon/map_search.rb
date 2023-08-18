module Article::Addon
  module MapSearch
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      field :map_search_options, type: Article::Extensions::MapSearchOptions, default: []
      permit_params map_search_options: [:name, :values]
    end

    def map_category_options
      st_categories.map { |c| [c.name, c.id] }
    end
  end
end
