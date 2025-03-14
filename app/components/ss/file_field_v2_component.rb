#frozen_string_literal: true

class SS::FileFieldV2Component < ApplicationComponent
  include ActiveModel::Model
  include ApplicationHelper

  attr_accessor :object_name, :object_method
  attr_writer :ss_mode, :cur_site, :cur_user, :cur_node, :item, :file

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
    @file = item.send(object_method)
  end

  def sanitize_to_id(name)
    name.to_s.delete("]").tr("^-a-zA-Z0-9:.", "_")
  end

  def element_id
    @element_id ||= sanitize_to_id("#{object_name}[#{object_method}_id]")
  end

  def upload_api_path
    @upload_api_path ||= begin
      case ss_mode
      when :cms
        cms_frames_temp_files_uploads_path(site: cur_site, cid: cur_node || "-")
      else
        sns_frames_temp_files_uploads_path(user: cur_user)
      end
    end
  end

  def select_api_path
    @select_api_path ||= begin
      case ss_mode
      when :cms
        select_cms_frames_temp_files_file_path(site: cur_site, cid: cur_node || "-", id: ':id', format: :json)
      else
        select_sns_frames_temp_files_file_path(user: cur_user, id: ':id', format: :json)
      end
    end
  end
end
