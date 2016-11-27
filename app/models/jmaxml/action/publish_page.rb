class Jmaxml::Action::PublishPage < Jmaxml::Action::Base
  include Jmaxml::Addon::PublishPage

  def execute(page, context)
    renderer = context.type.renderer
    page = renderer.create(page, context, self)
    page.cur_site = context.site
    page.cur_node = publish_to
    page.state = publish_state
    page.category_ids = category_ids
    page.save!
  end
end
