module Article::Addon
  module MapSearchResult
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      field :map_html, type: String
      field :sidebar_loop_liquid, type: String
      field :map_marker_liquid, type: String

      permit_params :map_html, :sidebar_loop_liquid, :map_marker_liquid, :map_cluster_state
    end

    def default_map_html
      <<~HTML
        {{ sidebar }}
        {{ filters }}
        {{ canvas }}
      HTML
    end

    def default_sidebar_loop_liquid
      <<~HTML
        {% for page in pages %}
        {% assign address = page | search_column_value: "所在地", "住所" %}
        <div class="column" data-id="{{ page.id }}">
          <p><a href="{{ page.url }}">{{ page.name }}</a></p>
          {% if address %}
          <p>{{ address.value }}</p>
          {% endif %}
          <p><a href="#" class="click-marker">地図上で確認</a></p>
        </div>
        {% endfor %}
      HTML
    end

    def default_map_marker_liquid
      <<~HTML
        <div class="marker-info" data-id="{{ page.id }}">
          <p class="name">{{ page.name }}</p>
          <p class="show"><a href="{{ page.url }}">詳細を見る</a></p>
        </div>
      HTML
    end

    def form_example_map_html
      default_map_html
    end

    def form_example_sidebar_loop_liquid
      default_sidebar_loop_liquid
    end

    def form_example_map_marker_liquid
      default_map_marker_liquid
    end
  end
end
