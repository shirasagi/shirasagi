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
    @cms_sites ||= begin
      sites = SS::Site.all.and("$or" => [ { domains: request_host }, { mypage_domain: request_host } ])
      sites = sites.order_by(id: 1)
      sites.to_a
    end
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
      SS.change_locale_and_timezone(SS.current_user)
      user
    end
  end

  def cur_item
    return @cur_item if @cur_item

    id = params[:id_path].present? ? params[:id_path].delete('/') : params[:id]
    name_or_filename = params[:filename]
    name_or_filename << ".#{params[:format]}" if params[:format].present?

    begin
      item = SS::File.find(id)
    rescue Mongoid::Errors::DocumentNotFound
      Rails.logger.warn { "#{id} is not found" }
      raise
    end

    item = item.becomes_with_model

    if item.name == name_or_filename || item.filename == name_or_filename
      @cur_item = item
      @cur_variant = nil
      return
    end

    variant = item.variants.from_filename(name_or_filename)
    if !variant
      Rails.logger.warn { "name or filename '#{name_or_filename}' is mismatched" }
      raise "404"
    end

    @cur_item = item
    @cur_variant = variant

    @cur_item
  end

  def cur_variant
    cur_item
    @cur_variant
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

  def cur_member
    return @cur_member if instance_variable_defined?(:@cur_member)

    @cur_member = begin
      cur_site # ensure to set "@cur_site" member variable
      get_member_by_session
    end
  end

  def deny
    member = cur_member

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

  def send_item(disposition = nil)
    path = cur_variant ? cur_variant.path : cur_item.path
    cur_variant.create! if cur_variant
    raise "404" unless Fs.file?(path)

    set_last_modified

    content_type = cur_variant ? cur_variant.content_type : cur_item.content_type
    content_type = content_type.presence || SS::MimeType::DEFAULT_MIME_TYPE

    disposition = :attachment unless SS::MimeType.safe_for_inline?(content_type)
    disposition ||= :inline

    download_filename = cur_variant ? cur_variant.download_filename : cur_item.download_filename
    ss_send_file cur_variant || cur_item, type: content_type, filename: download_filename, disposition: disposition
  rescue MiniMagick::Error => e
    Rails.logger.info("#{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}")
    head :not_found
  end

  public

  def index
    send_item
  end

  def thumb
    size   = params[:size]
    width  = params[:width]
    width  = width.numeric? ? width.to_i : nil
    height = params[:height]
    height = height.numeric? ? height.to_i : nil

    if width.present? && height.present? && width > 0 && height > 0
      @cur_variant = cur_item.variants[{ width: width, height: height }]
    elsif size.present? && (variant = cur_item.variants[size.to_s.to_sym])
      @cur_variant = variant
    elsif cur_item.respond_to?(:variants)
      @cur_variant = cur_item.variants[:thumb]
    end

    send_item
  rescue => e
    Rails.logger.warn { "#{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}" }
    raise "500"
  end

  def download
    send_item(DEFAULT_SEND_FILE_DISPOSITION)
  end

  alias view index
end
