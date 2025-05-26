#frozen_string_literal: true

class Cms::FileResizingSelectComponent < SS::FileResizingSelectComponent
  include ActiveModel::Model

  attr_accessor :cur_node
  attr_writer :cur_site

  def cur_site
    return @cur_site if instance_variable_defined?(:@cur_site)
    @cur_site = cur_node.try(:site)
  end

  private

  def user_image_resize
    return @user_image_resize if instance_variable_defined?(:@user_image_resize)
    @user_image_resize = SS::File.effective_image_resize(
      user: cur_user, site: cur_site, node: cur_node, request_disable: true)
  end

  def system_image_resize
    return @system_image_resize if instance_variable_defined?(:@system_image_resize)
    @system_image_resize = SS::File.effective_image_resize(
      user: cur_user, site: cur_site, node: cur_node, request_disable: false)
  end

  def additional_options
    @additional_options ||= begin
      additional_options = []

      site_resizing = cur_site.try(:file_resizing)
      if site_resizing.present?
        site_resizing_label = Cms::Site.t(:file_resizing_label, size: site_resizing.join("x"))
        additional_options << {
          width: site_resizing[0], height: site_resizing[1], label: site_resizing_label
        }
      end

      if system_image_resize.present? && (system_image_resize.max_width || system_image_resize.max_height)
        w = system_image_resize.max_width
        h = system_image_resize.max_height
        if additional_options.none? { _1[:width] == w && _1[:height] == h }
          additional_options << { width: w, height: h, label: I18n.t("ss.auto_resizing_label", size: "#{w}x#{h}") }
        end
      end

      additional_options
    end
  end
end
