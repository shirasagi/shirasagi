class Jmaxml::Action::PublishPage < Jmaxml::Action::Base
  include Jmaxml::Addon::Action::PublishPage
  include Jmaxml::Addon::Action::PublishingOffice

  def execute(page, context)
    renderer = context.type.renderer
    page = renderer.create(page, context, self)
    page.cur_site = context.site
    publish_to.try do |node|
      page.cur_node = node
      page.layout_id = node.page_layout_id || node.layout_id
    end
    page.state = publish_state
    page.category_ids = category_ids
    page.contact_group = page.cur_node.groups.first
    page.save!
  end
end
