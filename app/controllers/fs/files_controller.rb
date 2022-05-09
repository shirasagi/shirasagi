class Fs::FilesController < ApplicationController
  include SS::AuthFilter
  include Member::AuthFilter

  around_action :around_tagged_url
  before_action :cur_user
  before_action :cur_item
  before_action :deny
  rescue_from StandardError, with: :rescue_action

  private

  def around_tagged_url(&block)
    Rails.logger.tagged(request.url, &block)
  end

  def cms_sites
    # サブディレクトリ型サブサイトの /fs と親サイトの /fs とは区別がつかない。
    # つまり、リクエスト・ホストからは一意にどのサイトの /fs にアクセスしているのか、容易に判別することはできない。
    @cms_sites ||= SS::Site.all.in(domains: request_host).order_by(id: 1).to_a
  end

  def canonical_site
    @canonical_site ||= begin
      if cms_sites.length <= 1
        cms_sites.first
      else
        cms_sites.find { |site| site.parent_id.blank? } || cms_sites.first
      end
    end
  end

  def cur_user
    @cur_user ||= begin
      user, _login_path, _logout_path = get_user_by_access_token
      user ||= get_user_by_session
      SS.current_user = user
      user
    end
  end

  def cur_item
    @cur_item ||= begin
      id = params[:id_path].present? ? params[:id_path].delete('/') : params[:id]
      name_or_filename = params[:filename]
      name_or_filename << ".#{params[:format]}" if params[:format].present?

      begin
        item = SS::File.find(id)
      rescue Mongoid::Errors::DocumentNotFound
        Rails.logger.warn { "#{id} is not found" }
        raise
      end
      if item.name != name_or_filename && item.filename != name_or_filename
        Rails.logger.warn { "name or filename is not matched" }
        raise "404"
      end

      item = item.becomes_with_model
      if item.try(:thumb?)
        Rails.logger.warn { "requested file is a thumbnail file" }
        raise "404"
      end

      item
    end
  end

  def cur_site
    @cur_site ||= begin
      if cms_sites.length <= 1
        # リクエスト・ホストから一意にサイトが決まるケース
        cms_sites.first
      else
        # リクエスト・ホストから一意にサイトが決まらないケース
        owner_item = cur_item.send(:effective_owner_item)
        if owner_item.try(:site) && owner_item.site.is_a?(SS::Model::Site)
          # owner_item is a cms object.
          cms_sites.find { |site| site.id == owner_item.site_id }
        elsif cur_item.try(:site) && cur_item.site.is_a?(SS::Model::Site)
          # cur_item is a cms object.
          cms_sites.find { |site| site.id == cur_item.site_id }
        end
      end
    end
  end

  def deny
    member = get_member_by_session

    tags = []
    tags << "file:#{cur_item.id}(#{cur_item.filename})" if cur_item
    tags << "site:#{cur_site.host}(#{cur_site.name})" if cur_site
    tags << "user:#{cur_user.long_name}" if cur_user
    tags << "member:#{member.id}(#{member.name})" if member

    Rails.logger.tagged(*tags) do
      raise "404" unless cur_item.previewable?(site: cur_site, user: cur_user, member: member)
      set_last_logged_in
    end
  end

  def set_last_modified
    response.headers["Last-Modified"] = CGI::rfc1123_date(cur_item.updated.in_time_zone)
  end

  def rescue_action(error = nil)
    if error.to_s.numeric?
      status = error.to_s.to_i
      file = error_html_file(status)
      return ss_send_file(file, status: status, type: Fs.content_type(file), disposition: :inline)
    end
    if error.is_a?(Mongoid::Errors::DocumentNotFound)
      status = 404
      file = error_html_file(status)
      return ss_send_file(file, status: status, type: Fs.content_type(file), disposition: :inline)
    end
    raise error
  end

  def error_html_file(status)
    if canonical_site && cur_user.nil?
      file = "#{canonical_site.path}/#{status}.html"
      return file if Fs.exist?(file)
    end

    file = "#{Rails.public_path}/.error_pages/#{status}.html"
    Fs.exist?(file) ? file : "#{Rails.public_path}/.error_pages/500.html"
  end

  def send_item(disposition = :inline)
    set_last_modified

    if Fs.mode == :file && Fs.file?(cur_item.path)
      send_file cur_item.path, type: cur_item.content_type, filename: cur_item.download_filename,
                disposition: disposition, x_sendfile: true
    else
      send_enum cur_item.to_io, type: cur_item.content_type, filename: cur_item.download_filename,
                disposition: disposition
    end
  end

  def send_thumb(file, opts = {})
    width  = opts.delete(:width).to_i
    height = opts.delete(:height).to_i

    width  = (width  > 0) ? width  : SS::ImageConverter::DEFAULT_THUMB_WIDTH
    height = (height > 0) ? height : SS::ImageConverter::DEFAULT_THUMB_HEIGHT

    converter = SS::ImageConverter.open(file.path)
    converter.resize_to_fit!(width, height)

    send_enum converter.to_enum, opts
    converter = nil
  ensure
    if converter
      converter.close rescue nil
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

    if width.present? && height.present?
      set_last_modified
      send_thumb cur_item, type: cur_item.content_type, filename: cur_item.filename,
        disposition: :inline, width: width, height: height
    elsif thumb = cur_item.try(:thumb, size)
      @cur_item = thumb
      index
    else
      set_last_modified
      send_thumb cur_item, type: cur_item.content_type, filename: cur_item.filename,
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
