class Cms::MobileSizeCheckController < ApplicationController
  protect_from_forgery except: :check
  skip_before_action :verify_authenticity_token unless SS.config.env.csrf_protect
  before_action :accept_cors_request

  def check
    result = {}
    imgs_ids = params[:img_ids]
    mobile_size = params[:mobile_size]
    is_thumb = params[:is_thumb]

    raise "400" if imgs_ids.blank?
    imgs_ids = imgs_ids.values if imgs_ids.is_a?(Hash)
    ids = imgs_ids.map { |e| e.to_i }

    img_files = SS::File.where(:id.in => ids)
    size = 0
    result[:file_id] = []
    result[:errors] = []
    img_files.each do |file|
      next if result[:file_id].include?(file.id)

      if is_thumb[file.id.to_s]
        if file.thumb.size > 0
          result[:errors] << I18n.t(
            "errors.messages.too_bigfile",
            filename: file.name,
            filesize: view_context.number_to_human_size(file.thumb.size)
          )
        end

        size += file.thumb.size
      else
        if file.size > 0
          result[:errors] << I18n.t(
            "errors.messages.too_bigfile",
            filename: file.name,
            filesize: view_context.number_to_human_size(file.size)
          )
        end

        size += file.size
        result[:file_id] << file.id
      end

    end
    if size > mobile_size
      result[:errors] << I18n.t("errors.messages.too_bigsize")
    end
    result[:size] = size

    respond_to do |format|
      format.json { render json: result.to_json }
    end
  end

end
