#frozen_string_literal: true

class SS::FileFieldComponent < ApplicationComponent
  include ActiveModel::Model

  attr_accessor :object_name, :object_method
  attr_writer :ss_mode, :cur_site, :cur_user, :cur_node, :item, :file, :element_id

  delegate :sanitizer_status, to: :helpers

  def ss_mode
    @ss_mode || view_context.instance_variable_get(:@ss_mode)
  end

  def cur_site
    @cur_site || view_context.instance_variable_get(:@cur_site)
  end

  def cur_user
    @cur_user || view_context.instance_variable_get(:@cur_user)
  end

  def cur_node
    @cur_node || view_context.instance_variable_get(:@cur_node)
  end

  def item
    @item || view_context.instance_variable_get(:"@#{object_name}")
  end

  def file
    @file ||= item.send(object_method)
  end

  def element_id
    @element_id ||= sanitize_to_id("#{object_name}[#{object_method}_id]")
  end

  def temp_files_api_path
    @temp_files_api_path ||= begin
      case ss_mode
      when :cms
        if cur_node
          view_context.cms_apis_node_temp_files_path(site: cur_site, cid: cur_node)
        else
          view_context.cms_apis_temp_files_path(site: cur_site)
        end
      else
        view_context.sns_apis_temp_files_path(user: cur_user)
      end
    end
  end

  private

  def sanitize_to_id(name)
    name.to_s.delete("]").tr("^-a-zA-Z0-9:.", "_")
  end
end
