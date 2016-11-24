class Jmaxml::Action::PublishPage < Jmaxml::Action::Base
  include Jmaxml::Addon::PublishPage

  def execute(page, context)
    renderer = context.type.renderer(page, context)
    title = renderer.render_title
    html = renderer.render_html

    Article::Page.create!(
      cur_site: context.site, cur_node: publish_to,
      state: publish_state, name: title, html: html, category_ids: category_ids)
  end
end
