class Gws::Workflow2::ApproverOption::SuperiorComponent < ApplicationComponent
  include ActiveModel::Model
  include SS::CacheableComponent

  attr_accessor :cur_site, :cur_user, :cur_group

  delegate :gws_public_user_long_name, to: :helpers

  self.cache_key = proc do
    [ I18n.locale, cur_site.id, superior.try(:id), max_updated.to_i ]
  end

  def superior
    return @superior if instance_variable_defined?(:@superior)

    if cur_group.superior_id.blank?
      @superior = nil
      return @superior
    end

    criteria = Gws::User.site(cur_site)
    criteria = criteria.active
    criteria = criteria.where(id: cur_group.superior_id)
    criteria = criteria.only(:id, :name, :uid, :email, :updated)
    @superior = criteria.first
  end

  def max_updated
    @superior.try(:updated)
  end

  def render?
    superior.present?
  end

  def call
    cache_component do
      tag.optgroup(label: I18n.t("mongoid.attributes.gws/addon/group/affair_setting.superior_user_ids")) do
        label = gws_public_user_long_name(superior.long_name)
        tag.option(
          "#{label} (#{I18n.t("mongoid.attributes.gws/addon/group/affair_setting.superior_user_ids")})",
          value: superior.id, data: { type: 'superior' })
      end
    end
  end
end
