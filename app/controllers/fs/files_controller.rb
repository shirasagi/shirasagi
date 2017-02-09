class Fs::FilesController < ApplicationController
  include SS::AuthFilter
  include Member::AuthFilter
  include Fs::FileFilter

  before_action :set_item
  before_action :deny
  rescue_from StandardError, with: :rescue_action

  private
    def set_item
      id = params[:id_path].present? ? params[:id_path].gsub(/\//, "") : params[:id]
      path = params[:filename]
      path << ".#{params[:format]}" if params[:format].present?

      @item = SS::File.find_by id: id, filename: path
      raise "404" if @item.thumb?
    end

    def deny
      return if @item.public?
      return if SS.config.env.remote_preview

      user   = get_user_by_session
      member = get_member_by_session
      item   = @item.becomes_with_model
      raise "404" unless item.previewable?(user: user, member: member)

      set_last_logged_in
    end

    def set_last_modified
      response.headers["Last-Modified"] = CGI::rfc1123_date(@item.updated.in_time_zone)
    end

    def rescue_action(e = nil)
      if e.to_s =~ /^\d+$/
        status = e.to_s.to_i
        return render status: status, file: error_template(status), layout: false
      end
      raise e
    end

    def error_template(status)
      file = "#{Rails.public_path}/#{status}.html"
      Fs.exists?(file) ? file : "#{Rails.public_path}/500.html"
    end

  public
    def index
      set_last_modified

      if Fs.mode == :file && Fs.file?(@item.path)
        send_file @item.path, type: @item.content_type, filename: @item.filename,
          disposition: :inline, x_sendfile: true
      else
        send_data @item.read, type: @item.content_type, filename: @item.filename,
          disposition: :inline
      end
    end

    def thumb
      size   = params[:size]
      width  = params[:width]
      height = params[:height]
      thumb  = @item.thumb(size)

      if width.present? && height.present?
        set_last_modified
        send_thumb @item.read, type: @item.content_type, filename: @item.filename,
          disposition: :inline, width: width, height: height
      elsif thumb
        @item = thumb
        index
      else
        set_last_modified
        send_thumb @item.read, type: @item.content_type, filename: @item.filename,
          disposition: :inline
      end
    rescue => e
      raise "500"
    end
end
