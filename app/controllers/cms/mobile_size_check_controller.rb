require "timeout"
require "open-uri"

class Cms::MobileSizeCheckController < ApplicationController
  protect_from_forgery except: :check
  skip_before_action :verify_authenticity_token unless SS.config.env.csrf_protect
  before_action :accept_cors_request

  def check
    result = {}
    imgs_ids = params[:img_ids]
    mobile_size = params[:mobile_size]

    raise "400" if imgs_ids.blank?
    imgs_ids = imgs_ids.values if imgs_ids.is_a?(Hash)
    ids = imgs_ids.map { |e| e.to_i }

    img_files = SS::File.where(:id.in => ids)
    size = 0
    result[:file_name] = []
    result[:errors] = []
    img_files.each do |file|
      next if result[:file_name].include?(file.name)
      size += file.size
      if size > mobile_size
        result[:errors] << I18n.t("errors.messages.too_bigsize")
      end
      result[:file_name] << file.name
    end
    result[:size] = size

    respond_to do |format|
      format.json { render json: result.to_json }
    end
  end

end
