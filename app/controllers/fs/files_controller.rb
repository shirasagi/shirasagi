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
    @cur_site = @item.try(:site)
    # TODO: validate site

    return deny_gws if @item.model.to_s.start_with?('gws/')

    return if @item.public?
    return if SS.config.env.remote_preview

    user   = get_user_by_session
    member = get_member_by_session
    item   = @item.becomes_with_model
    raise "404" unless item.previewable?(user: user, member: member)

    set_last_logged_in
  end

  def deny_gws
    user = get_user_by_session
    raise "404" unless user

    @cur_user = user.gws_user

    doc = @item.model.camelize.constantize
    keys = doc.fields.keys & ['file_id', 'file_ids']
    raise "404" if keys.blank?

    docs = doc.site(@cur_site).or([{ file_id: @item.id }, { file_ids: @item.id }])
    docs = docs.select do |d|
      d.cur_site = @cur_site
      d.readable?(@cur_user, site: @cur_site) || d.try(:member?, @cur_user)
    end
    raise "404" if docs.size == 0

    set_last_logged_in
  end

  def set_last_modified
    response.headers["Last-Modified"] = CGI::rfc1123_date(@item.updated.in_time_zone)
  end

  def rescue_action(e = nil)
    if e.to_s =~ /^\d+$/
      status = e.to_s.to_i
      file = error_html_file(status)
      return ss_send_file(file, status: status, type: Fs.content_type(file), disposition: :inline)
    end
    raise e
  end

  def error_html_file(status)
    file = "#{Rails.public_path}/#{status}.html"
    Fs.exists?(file) ? file : "#{Rails.public_path}/500.html"
  end

  def send_item(disposition = :inline)
    set_last_modified

    filename = @item.name.presence || @item.filename

    if Fs.mode == :file && Fs.file?(@item.path)
      send_file @item.path, type: @item.content_type, filename: filename,
                disposition: disposition, x_sendfile: true
    else
      send_data @item.read, type: @item.content_type, filename: filename,
                disposition: disposition
    end
  end

  public

  def index
    send_item
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

  def download
    send_item(DEFAULT_SEND_FILE_DISPOSITION)
  end

  alias view index
end
