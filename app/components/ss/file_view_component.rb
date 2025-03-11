#frozen_string_literal: true

class SS::FileViewComponent < ApplicationComponent
  include ActiveModel::Model
  include ViewComponent::SlotableDefault
  include ApplicationHelper

  attr_accessor :cur_site, :cur_user, :cur_node, :file, :item
  attr_writer :page, :name, :show_properties, :show_attach, :show_delete, :show_copy_url

  renders_one :attach_action
  renders_one :image_paste_action
  renders_one :thumb_paste_action
  renders_one :delete_action
  renders_one :copy_url_action

  def licenses
    return @licenses if instance_variable_defined?(:@licenses)

    if cur_node.blank?
      @licenses = []
      return @licenses
    end


    criteria = Opendata::License.all
    criteria = criteria.in(site_id: cur_node.try(:opendata_site_ids))
    criteria = criteria.and_public
    @licenses = criteria.pluck(:name, :id)
  end

  def page
    @page.presence || item
  end

  def name
    @name || "item[file_ids][]"
  end

  def show_properties
    return @show_properties if instance_variable_defined?(:@show_properties)
    true
  end

  def show_attach
    return @show_attach if instance_variable_defined?(:@show_attach)
    true
  end

  def show_delete
    return @show_delete if instance_variable_defined?(:@show_delete)
    true
  end

  def show_copy_url
    return @show_copy_url if instance_variable_defined?(:@show_copy_url)
    false
  end

  def default_attach_action
    link_to t("sns.file_attach"), "#file-#{file.id}", class: "action-attach"
  end

  def default_image_paste_action
    link_to t("sns.image_paste"), "#file-#{file.id}", class: "action-paste"
  end

  def default_thumb_paste_action
    link_to t("sns.thumb_paste"), "#file-#{file.id}", class: "action-thumb"
  end

  def default_delete_action
    link_to t("ss.buttons.delete"), "#file-#{file.id}", class: "action-delete"
  end

  def default_copy_url_action
    link_to t("ss.buttons.copy_url"), "#file-#{file.id}", class: "action-copy-url"
  end
end
