class Opendata::Agents::Pages::AppController < ApplicationController
  include Cms::PageFilter::View
  include Opendata::UrlHelper
  helper Opendata::UrlHelper

  public
    def index
      @cur_node = @cur_page.parent.becomes_with_route
      @cur_page.layout_id = @cur_node.page_layout_id || @cur_node.layout_id

      @search_url = search_apps_path

      appli = Opendata::App.find(@cur_page.id)
      @app_html = appli.appfiles.where(format: "HTML").first
      if @app_html.present?
        @app_index = "/app/#{@cur_page.id}/appfile/#{@app_html.filename}"
        @text = "/text/#{@cur_page.id}/appfile/"
        @html_text = "#{@text}#{@app_html.filename}"

        @app_js = []
        @app_css = []
        appli.appfiles.each do |file|
          if file.format == "JS"
            @app_js.push(file)
          elsif file.format == "CSS"
            @app_css.push(file)
          end
        end
      end

      if @cur_page.dataset_ids.empty? == false
        @ds = Opendata::Dataset.site(@cur_site).public.find(@cur_page.dataset_ids)
      end

      render
    end
end
