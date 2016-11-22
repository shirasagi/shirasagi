class Jmaxml::Action::PublishPage < Jmaxml::Action::Base
  belongs_to :publish_to, class_name: "Cms::Node"
  field :publish_state, type: String
  embeds_ids :categories, class_name: "Cms::Node"
  permit_params :publish_to_id, :publish_state
  permit_params category_ids: []

  def publish_state_options
    %w(draft public).map { |v| [ I18n.t("views.options.state.#{v}"), v ] }
  end

  def execute(page, context)
    renderer = context.type.renderer(page, context)
    title = renderer.render_title
    html = renderer.render_html

    Article::Page.create!(
      cur_site: context.site, cur_node: publish_to,
      state: publish_state, name: title, html: html, category_ids: category_ids)
  end
end
