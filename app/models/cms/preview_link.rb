class Cms::PreviewLink
  attr_reader :site, :url, :preview_base, :preview_path, :scheme, :expanded

  # Addressable::URI::URIREGEX
  # /^(([^:\/?#]+):)?(\/\/([^\/?#]*))?([^?#]*)(\?([^#]*))?(#(.*))?$/
  SCHEMEREGEX = /^([^:\/?#]+):/

  def initialize(site, preview_base, preview_path, url)
    @site = site
    @preview_base = preview_base
    @preview_path = preview_path.to_s
    @url = url
    set_expanded
  end

  def internal?
    @internal
  end

  def external?
    !internal?
  end

  private

  def set_expanded
    @scheme = url.scan(SCHEMEREGEX).flatten.first
    if scheme.present?
      set_expanded_on_scheme
    else
      set_expanded_off_scheme
    end
  end

  def set_expanded_on_scheme
    if scheme != "http" && scheme != "https"
      @internal = true
      @expanded = url
      return
    end

    full_url = site.full_url.delete_suffix("/")
    full_root_url = site.full_root_url.delete_suffix("/")

    if url.start_with?(full_url)
      path = url.delete_prefix(full_root_url)
      path = "/" + path if path[0] != "/"
      @internal = cur_site_path?(path)
      @expanded = internal? ? (preview_base + path) : url
    else
      @internal = false
      @expanded = url
    end
  end

  def set_expanded_off_scheme
    # assets
    if url =~ /^\/(assets|assets-dev)\//
      @internal = true
      @expanded = url
      return
    end

    # #
    if url[0] == "#"
      @internal = true
      @expanded = url
      return
    end

    # / ./ ../ index.html
    if preview_path.end_with?(".html")
      dir = ::File.dirname(site.url + preview_path)
    else
      dir = site.url + preview_path
    end
    path = Pathname(dir).join(url).to_s
    @internal = cur_site_path?(path)
    @expanded = internal? ? (preview_base + path) : url
  end

  def cur_site_path?(path)
    same_site = site.same_domain_site_from_path(path)
    same_site && (same_site.id == site.id)
  end
end
