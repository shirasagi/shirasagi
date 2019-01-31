class Ckan::Agents::Parts::ReferenceController < ApplicationController
  include Cms::PartFilter::View

  def index
    filename = @cur_main_path.sub(/\/[^\/]+?$/, "").sub(/^\//, "")

    @url = @cur_part.exporter.url
    @node = Cms::Node.site(@cur_site).where(filename: filename).first

    if @node.nil?
      filename = @cur_main_path.sub(/\/[^\/]+?$/, "")
      Opendata::Node::Dataset.site(@cur_site).each do |search_node|
        filename.sub!(search_node.url, "")
      end
      filename.sub!(/^\//, "")
      @node = Cms::Node.site(@cur_site).where(filename: filename).first
    end

    return unless @node

    if @node.route == "opendata/category" || @node.route == "opendata/estat_category"
      group_setting = @cur_part.exporter.group_settings.in(category_ids: @node.id).first
      if group_setting
        @url = ::File.join(@url, "group/#{group_setting.ckan_name}")
      else
        @url = ::File.join(@url, "dataset?q=#{@node.name}")
      end
    elsif @node.route == "opendata/search_dataset"
      @category_id = params.dig("s", "category_id").to_i
      @estat_category_id = params.dig("s", "estat_category_id").to_i

      group_setting = @cur_part.exporter.group_settings.in(category_ids: @category_id).first
      group_setting ||= @cur_part.exporter.group_settings.in(estat_category_ids: @estat_category_id).first

      if group_setting
        @url = ::File.join(@url, "group/#{group_setting.ckan_name}")
      else
        @category_node = Cms::Node.site(@cur_site).where(id: @category_id).first
        @category_node ||= Cms::Node.site(@cur_site).where(id: @estat_category_id).first

        @url = ::File.join(@url, "dataset?q=#{@category_node.name}") if @category_node
      end
    end
  end
end
