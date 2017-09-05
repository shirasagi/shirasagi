class Cms::SearchContents::HtmlController < ApplicationController
  include Cms::BaseFilter
  include Cms::ApiFilter::Contents

  model Cms::Page

  navi_view "cms/search_contents/navi"

  def index
    raise "403" unless Cms::Tool.allowed?(:edit, @cur_user, site: @cur_site)

    @keyword = params[:keyword]
    @replacement = params[:replacement]
    @updated_items = flash[:updated_items]
    if @updated_items
      page_ids   = @updated_items["update_pages"].split(",")
      layout_ids = @updated_items["update_layouts"].split(",")
      part_ids   = @updated_items["update_parts"].split(",")

      @pages = Cms::Page.site(@cur_site).in(id: page_ids).order_by(filename: 1).limit(500)
      @parts = Cms::Part.site(@cur_site).in(id: part_ids).order_by(filename: 1).limit(500)
      @layouts = Cms::Layout.site(@cur_site).in(id: layout_ids).order_by(filename: 1).limit(500)
    end
  end

  def update
    keyword     = params[:keyword].to_s
    replacement = params[:replacement].to_s
    option      = params[:option]
    page_ids    = params[:page_ids].to_a.map(&:to_i)
    part_ids    = params[:part_ids].to_a.map(&:to_i)
    layout_ids  = params[:layout_ids].to_a.map(&:to_i)

    @pages   = []
    @layouts = []
    @parts   = []

    begin
      raise "400" if keyword.blank?
      if option == "regexp"
        search_html_with_regexp(keyword)
        exclude_search_results(page_ids, part_ids, layout_ids)
        replace_html_with_regexp(keyword, replacement)
      elsif option == "url"
        search_html_with_url(keyword)
        exclude_search_results(page_ids, part_ids, layout_ids)
        replace_html_with_url(keyword, replacement)
      else
        search_html_with_string(keyword)
        exclude_search_results(page_ids, part_ids, layout_ids)
        replace_html_with_string(keyword, replacement)
      end
    rescue => e
      #
    end

    location = {
      action: :index,
      keyword: keyword,
      replacement: replacement,
    }
    flash[:updated_items] = {
      "update_pages" => @pages.map(&:id).join(","),
      "update_layouts" => @layouts.map(&:id).join(","),
      "update_parts" => @parts.map(&:id).join(","),
    }
    redirect_to location, notice: t("ss.notice.saved")
  end

  private

  def replace_html_with_string(string, replacement)
    @pages = @pages.select do |item|
      update_html_fields(item) { |html| html.gsub(string, replacement) }
    end

    @parts = @parts.select do |item|
      update_html_fields(item) { |html| html.gsub(string, replacement) }
    end

    @layouts = @layouts.select do |item|
      update_html_fields(item) { |html| html.gsub(string, replacement) }
    end
  end

  def replace_html_with_url(src_url, dest_url)
    src_path  = "=\"#{src_url}"
    dest_path = "=\"#{dest_url}"

    @pages = @pages.select do |item|
      update_html_fields(item) { |html| html.gsub(src_path, dest_path) }
    end

    @parts = @parts.select do |item|
      update_html_fields(item) { |html| html.gsub(src_path, dest_path) }
    end

    @layouts = @layouts.select do |item|
      update_html_fields(item) { |html| html.gsub(src_path, dest_path) }
    end
  end

  def replace_html_with_regexp(string, replacement)
    regexp = Regexp.new(string, Regexp::MULTILINE)

    @pages = @pages.select do |item|
      update_html_fields(item) { |html| html.gsub(regexp, replacement) }
    end

    @parts = @parts.select do |item|
      update_html_fields(item) { |html| html.gsub(regexp, replacement) }
    end

    @layouts = @layouts.select do |item|
      update_html_fields(item) { |html| html.gsub(regexp, replacement) }
    end
  end

  def exclude_search_results(page_ids, part_ids, layout_ids)
    @pages   = @pages.in(id: page_ids).order_by(filename: 1).limit(500)
    @layouts = @layouts.in(id: layout_ids).order_by(filename: 1).limit(500)
    @parts   = @parts.in(id: part_ids).order_by(filename: 1).limit(500)
  end

  def update_html_fields(item)
    item = item.becomes_with_route if item.try(:route)

    attributes = {}
    HTML_FIELDS.each do |field|
      next unless item.try(field)
      html = yield item.send(field)
      attributes[field] = html if item.send(field) != html
    end

    if attributes.present?
      item.set(attributes)
      true
    else
      false
    end
  end
end
