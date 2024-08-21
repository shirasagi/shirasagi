class Gws::Workflow2::RouteOption::UserUnderCurGroupComponent < ApplicationComponent
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
      criteria = criteria.active
      criteria = criteria.order_by_title(cur_site)
      criteria = criteria.only(:id, :name, :uid, :email, :updated)
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
      tag.optgroup(label: I18n.t("gws/workflow2.options.route_optgroup.my_group"), class: "my_group") do
        items.each do |item|
          label = gws_public_user_long_name(item.long_name)
          output_buffer << tag.option(label, value: item.id, data: { type: item.class.name })
        end
      end
    end
  end
end
