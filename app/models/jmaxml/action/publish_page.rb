class Jmaxml::Action::PublishPage < Jmaxml::Action::Base
  include Jmaxml::Addon::Action::PublishPage
  include Jmaxml::Addon::Action::PublishingOffice

  def execute(page, context)
    renderer = context.type.renderer
    page = renderer.create(page, context, self)

    page.class.with_repl_master do |model|
      item = model.new
      item.attributes = page.attributes
      item.cur_site = context.site
      item.cur_node = publish_to
      item.state = publish_state
      item.category_ids = category_ids
      item.save!
    end
  end
end
