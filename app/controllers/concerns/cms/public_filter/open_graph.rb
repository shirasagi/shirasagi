module Cms::PublicFilter::OpenGraph
  extend ActiveSupport::Concern

  def opengraph(key, *values)
    @open_graphs ||= begin
      [
        [ 'og:type', @cur_site.opengraph_type ],
        [ 'og:url', ->() { @cur_item.full_url } ],
        [ 'og:site_name', @cur_site.name ],
        [ 'og:title', ->() { @window_name } ],
        [ 'og:description', ->() { twitter_description } ],
        [ 'og:image', ->() { opengraph_image_urls } ],
      ]
    end

    if values.blank?
      # getter
      ret = @open_graphs.select { |k, v| k == key }.map do |k, v|
        if v.is_a?(Proc)
          self.instance_exec(&v)
        else
          v
        end
      end
      ret.flatten
    else
      # setter
      @open_graphs.delete_if { |k, v| k == key }
      values.each do |value|
        @open_graphs << [ key, value ]
      end
    end
  end

  private

  def opengraph_image_urls
    urls = extract_image_urls
    if urls.blank?
      urls << @cur_site.opengraph_defaul_image_url if @cur_site.opengraph_defaul_image_url.present?
    end
    urls
  end
end
