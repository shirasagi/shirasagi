#frozen_string_literal: true

class SS::FileSelectBoxComponent < ApplicationComponent
  include ActiveModel::Model

  attr_accessor :ss_mode, :cur_site, :cur_user, :cur_node, :page, :item, :html_editor_id, :accepts
  attr_writer :field_name, :selection_type, :files, :upload_api_path, :file_api_path, :select_api_path, :view_api_path,
    :show_attach, :show_opendata

  def field_name
    @field_name ||= "item[file_ids][]"
  end

  def selection_type
    @selection_type ||= "append"
  end

  def files
    @files ||= item.files.reorder(id: -1)
  end

  def setting
    @setting ||= begin
      setting = { field_name: field_name, show_attach: show_attach, show_opendata: show_opendata, accepts: accepts }
      JSON::JWT.new(setting).sign(Rails.application.secret_key_base).to_s
    end
  end

  def upload_api_path
    @upload_api_path ||= begin
      if @ss_mode == :cms
        view_context.cms_frames_temp_files_uploads_path(site: cur_site, cid: cur_node || "-", setting: setting)
      else
        view_context.sns_frames_temp_files_uploads_path(user: cur_user, setting: setting)
      end
    end
  end

  def file_api_path
    @file_api_path ||= begin
      if @ss_mode == :cms
        view_context.cms_frames_temp_files_files_path(site: cur_site, cid: cur_node || "-", setting: setting)
      else
        view_context.sns_frames_temp_files_files_path(site: cur_site, cid: cur_node || "-", setting: setting)
      end
    end
  end

  def select_api_path
    @select_api_path ||= begin
      if @ss_mode == :cms
        view_context.select_cms_frames_temp_files_file_path(site: cur_site, cid: cur_node || "-", setting: setting, id: ':id')
      else
        view_context.sns_cms_frames_temp_files_file_path(site: cur_site, cid: cur_node || "-", setting: setting, id: ':id')
      end
    end
  end

  def view_api_path
    @view_api_path ||= begin
      if @ss_mode == :cms
        view_context.view_cms_apis_content_file_path(id: ":id")
      end
    end
  end

  def show_attach
    return @show_attach if instance_variable_defined?(:@show_attach)
    true
  end

  def show_opendata
    return @show_opendata if instance_variable_defined?(:@show_opendata)
    true
  end
end
