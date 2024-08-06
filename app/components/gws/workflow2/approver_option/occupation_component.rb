class Gws::Workflow2::ApproverOption::OccupationComponent < ApplicationComponent
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
      criteria = criteria.in(occupation_ids: occupations.pluck(:id))
      criteria = criteria.active
      criteria = criteria.order_by_title(cur_site)
      criteria = criteria.only(:id, :name, :uid, :email, :occupation_ids, :updated)
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
      tag.optgroup(label: Gws::UserOccupation.model_name.human) do
        items.each do |item|
          label = gws_public_user_long_name(item.long_name)
          occupation_id = item.occupation_ids.find { |occupation_id| id_occupation_map[occupation_id] }
          occupation = id_occupation_map[occupation_id] if occupation_id
          label = "#{label} (#{occupation.name})" if occupation
          output_buffer << tag.option(label, value: item.id, data: { type: Gws::UserOccupation.name })
        end
      end
    end
  end

  private

  def occupations
    @occupations ||= Gws::UserOccupation.site(cur_site).only(:id, :name)
  end

  def id_occupation_map
    @id_occupation_map ||= occupations.to_a.index_by(&:id)
  end
end
