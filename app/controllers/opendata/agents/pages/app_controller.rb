class Opendata::Agents::Pages::AppController < ApplicationController
  include Cms::PageFilter::View
  include Opendata::UrlHelper
  helper Opendata::UrlHelper

  public
    def index
      @cur_node = @cur_page.parent.becomes_with_route
      @cur_page.layout_id = @cur_node.page_layout_id || @cur_node.layout_id

      @search_url = search_apps_path

      @tab_display = ""

      if @cur_page.appurl.present?
        @tab_display = "tab_url"
      else
        appli = Opendata::App.find(@cur_page.id)
        @app_html = appli.appfiles.where(filename: "index.html").first
        if @app_html.present?
          @tab_display = "tab_html"

          @app_index = "/app/#{@cur_page.id}/application/#{@app_html.filename}"
          @text = "/text/#{@cur_page.id}/appfile/"

          @js_src = []
          @css_src = []
          @html_src = []
          appli.appfiles.each do |file|
            if file.format == "JS"
              @js_src.push(file)
            elsif file.format == "CSS"
              @css_src.push(file)
            elsif file.format == "HTML" or file.format == "HTM"
              @html_src.push(file)
            end
          end

          @sample = appli.appfiles.where(format: "CSV")
        end
      end

      if @cur_page.dataset_ids.empty? == false
        @ds = Opendata::Dataset.site(@cur_site).public.find(@cur_page.dataset_ids)
      end

      @app_idea = Opendata::Idea.site(@cur_site).public.where(app_ids: @cur_page.id)

      render
    end
end
