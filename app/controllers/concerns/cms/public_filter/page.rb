module Cms::PublicFilter::Page
  extend ActiveSupport::Concern
  include Cms::PublicFilter::Layout

  private
    def find_page(path)
      page = Cms::Page.site(@cur_site).filename(path).first
      return unless page
      @preview || page.public? ? page.becomes_with_route : nil
    end

    def render_page(page, env = {})
      path = "/.s#{@cur_site.id}/pages/#{page.route}/#{page.basename}"
      spec = recognize_agent path, env
      return unless spec

      @cur_page = page
      controller = page.route.sub(/\/.*/, "/agents/#{spec[:cell]}")

      agent = new_agent controller
      agent.controller.params.merge! spec
      agent.render spec[:action]
    end

  public
    def generate_page(page)
      @cur_site      = page.site
      @cur_path      = page.url
      @cur_main_path = @cur_path.sub(@cur_site.url, "/")
      @csrf_token    = false

      #self.params   = ActionController::Parameters.new format: "html"
      #self.request  = ActionDispatch::Request.new method: "GET"
      #self.response = ActionDispatch::Response.new

      agent = SS::Agent.new self.class
      self.params   = agent.controller.params
      self.request  = agent.controller.request
      self.response = agent.controller.response

      begin
        response.body = render_page page
        response.content_type ||= "text/html"
      rescue StandardError => e
        return if e.to_s == "404"
        return if e.is_a? Mongoid::Errors::DocumentNotFound
        raise e unless Rails.env.producton?
      end

      if response.content_type == "text/html" && page.layout
        html = render_to_string inline: render_layout(page.layout), layout: "cms/page"
      else
        html = response.body
      end

      write_file page, html
    end
end
