class Gws::Workflow2::ApproverOption::TitleComponent < ApplicationComponent
  include ActiveModel::Model
  include SS::CacheableComponent

  attr_accessor :cur_site, :cur_user, :cur_group

  delegate :gws_public_user_long_name, to: :helpers

  self.cache_key = proc do
    [ I18n.locale, cur_site.id, items.pluck(:id), max_updated.to_i ]
  end

  def items
    @items ||= begin
      criteria = Gws::User.site(cur_site)
      criteria = criteria.where(group_ids: cur_group.id)
      criteria = criteria.in(title_ids: titles.pluck(:id))
      criteria = criteria.active
      criteria = criteria.order_by_title(cur_site)
      criteria = criteria.only(:id, :name, :uid, :email, :title_ids, :updated)
      criteria
    end
  end

  def max_updated
    @max_updated ||= items.max(:updated)
  end

  def render?
    items.present?
  end

  def call
    cache_component do
      tag.optgroup(label: Gws::UserTitle.model_name.human) do
        items.each do |item|
          label = gws_public_user_long_name(item.long_name)
          title_id = item.title_ids.find { |title_id| id_title_map[title_id] }
          title = id_title_map[title_id] if title_id
          label = "#{label} (#{title.name})" if title
          output_buffer << tag.option(label, value: item.id, data: { type: Gws::UserTitle.name })
        end
      end
    end
  end

  private

  def titles
    @titles ||= Gws::UserTitle.site(cur_site).only(:id, :name)
  end

  def id_title_map
    @id_title_map ||= titles.to_a.index_by(&:id)
  end
end
