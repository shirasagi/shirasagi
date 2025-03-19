#frozen_string_literal: true

class SS::FileFieldV2Component < SS::FileFieldComponent
  # include ActiveModel::Model
  include SS::MaterialIconsHelper

  attr_accessor :accepts

  def upload_api_path
    @upload_api_path ||= begin
      case ss_mode
      when :cms
        cms_frames_temp_files_uploads_path(site: cur_site, cid: cur_node || "-", accepts: accepts)
      else
        sns_frames_temp_files_uploads_path(user: cur_user, accepts: accepts)
      end
    end
  end

  def select_api_path
    @select_api_path ||= begin
      case ss_mode
      when :cms
        select_cms_frames_temp_files_file_path(site: cur_site, cid: cur_node || "-", id: ':id', accepts: accepts, format: :json)
      else
        select_sns_frames_temp_files_file_path(user: cur_user, id: ':id', accepts: accepts, format: :json)
      end
    end
  end
end
