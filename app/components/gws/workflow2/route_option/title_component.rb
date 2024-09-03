class Gws::Workflow2::RouteOption::TitleComponent < ApplicationComponent
  include ActiveModel::Model
  include SS::CacheableComponent

  attr_accessor :cur_site, :cur_user, :cur_group

  self.cache_key = proc do
    [ I18n.locale, cur_site.id, items.pluck(:id), max_updated.to_i ]
  end

  def items
    @items ||= Gws::UserTitle.site(cur_site).only(:id, :name, :updated)
  end

  def max_updated
    @max_updated ||= items.max(:updated)
  end

  def render?
    items.present?
  end

  def call
    cache_component do
      tag.optgroup(label: I18n.t("gws/workflow2.options.route_optgroup.user_title"), class: "title") do
        items.each do |item|
          output_buffer << tag.option(item.name, value: item.id, data: { type: item.class.name })
        end
      end
    end
  end
end
