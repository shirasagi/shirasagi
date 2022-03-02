module Article::Addon
  module MapSearchResult
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      field :map_html, type: String

      permit_params :map_html
    end

    def default_map_html
      <<~HTML
        {{ sidebar }}
        {{ canvas }}
        {{ filters }}
      HTML
    end

    def form_example_map_html
      default_map_html
    end
  end
end
