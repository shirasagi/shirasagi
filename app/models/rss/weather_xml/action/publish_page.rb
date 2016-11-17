class Rss::WeatherXml::Action::PublishPage < Rss::WeatherXml::Action::Base
  belongs_to :publish_to, class_name: "Cms::Node"
  field :publish_state, type: String
  permit_params :publish_to_id, :publish_state

  def publish_state_options
    %w(draft public).map { |v| [ I18n.t("views.options.state.#{v}"), v ] }
  end

  def execute(page, context)
    renderer = context.type.renderer(page, context)
    title = renderer.render_title
    html = renderer.render_html

    Article::Page.create!(cur_site: context.site, cur_node: publish_to, state: publish_state, name: title, html: html)
  end
end
