#frozen_string_literal: true

class SS::FileFieldV2Component < SS::FileFieldComponent
  # include ActiveModel::Model
  include SS::MaterialIconsHelper

  attr_accessor :accepts

  def setting
    @setting ||= begin
      JSON::JWT.new({ accepts: accepts }).sign(Rails.application.secret_key_base).to_s
    end
  end

  def upload_api_path
    @upload_api_path ||= begin
      case ss_mode
      when :cms
        cms_frames_temp_files_uploads_path(site: cur_site, cid: cur_node || "-", setting: setting)
      else
        sns_frames_temp_files_uploads_path(user: cur_user, setting: setting)
      end
    end
  end

  def select_api_path
    @select_api_path ||= begin
      case ss_mode
      when :cms
        select_cms_frames_temp_files_file_path(site: cur_site, cid: cur_node || "-", setting: setting, id: ':id', format: :json)
      else
        select_sns_frames_temp_files_file_path(user: cur_user, setting: setting, id: ':id', format: :json)
      end
    end
  end
end
