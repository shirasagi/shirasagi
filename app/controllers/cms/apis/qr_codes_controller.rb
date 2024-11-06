class Cms::Apis::QrCodesController < ApplicationController
  include Cms::ApiFilter

  model Cms::Page

  before_action :set_target_url
  before_action :set_qr_settings

  private

  def set_target_url
    @url = params[:url]
    raise "404" if params[:url].blank?
  end

  def set_qr_settings
    @qr_settings = {
      png160: { size: 160, border_modules: 2 },
      png240: { size: 240, border_modules: 2 },
      png480: { size: 480, border_modules: 2 },
      svg: { module_size: 11, offset: 60, viewbox: true, fill: "ffffff" },
    }
  end

  public

  def index
    return download if params[:download]
  end

  def download
    case params[:download]
    when 'png160'
      qr_code = ::RQRCode::QRCode.new(@url)
      send_data ChunkyPNG::Image.from_datastream(qr_code.as_png(@qr_settings[:png160]).to_datastream),
        filename: "QRCode_160px.png"
    when 'png240'
      qr_code = ::RQRCode::QRCode.new(@url)
      send_data ChunkyPNG::Image.from_datastream(qr_code.as_png(@qr_settings[:png240]).to_datastream),
        filename: "QRCode_240px.png"
    when 'png480'
      qr_code = ::RQRCode::QRCode.new(@url)
      send_data ChunkyPNG::Image.from_datastream(qr_code.as_png(@qr_settings[:png480]).to_datastream),
        filename: "QRCode_480px.png"
    when 'svg'
      qr_code = ::RQRCode::QRCode.new(@url)
      send_data qr_code.as_svg(@qr_settings[:svg]), filename: "QRCode.svg"
    else
      raise "404"
    end
  end
end
