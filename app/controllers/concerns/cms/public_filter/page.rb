module Cms::PublicFilter::Page
  extend ActiveSupport::Concern
  include Cms::PublicFilter::Layout

  private

  def render_page(page, env = {})
    spec = recognize_page(page, env)
    return unless spec

    @cur_page = page
    controller = page.route.sub(/\/.*/, "/agents/#{spec[:cell]}")

    agent = new_agent controller
    agent.controller.params.merge! spec
    agent.render spec[:action]
  end

  public

  def find_page(path)
    page = Cms::Page.site(@cur_site).filename(path).first
    return unless page
    @preview || (page.public? && page.public_node?) ? page : nil
  end

  def recognize_page(page, env = {})
    path = "/.s#{@cur_site.id}/pages/#{page.route}/#{page.basename}"
    recognize_agent path, env
  end

  def generate_page(page)
    @cur_site      = page.site
    @cur_path      = page.url
    @cur_main_path = @cur_path.sub(@cur_site.url, "/")
    @csrf_token    = false
    @generate_page = true

    agent = SS::Agent.new self.class
    self.params   = agent.controller.params
    self.request  = agent.controller.request
    self.response = agent.controller.response

    begin
      response.body = render_page page
      response.content_type ||= "text/html"
    rescue StandardError => e
      return if SS.not_found_error?(e)
      raise e
    end

    if page.view_layout == "cms/redirect"
      @redirect_link = Sys::TrustedUrlValidator.url_restricted? ? trusted_url!(page.redirect_link) : page.redirect_link
      html = render_to_string html: "", layout: "cms/redirect"
    elsif response.media_type == "text/html" && page.layout
      html = render_to_string html: render_layout(page.layout).html_safe, layout: "cms/page"
    else
      html = response.body
    end

    Fs.write_data_if_modified page.path, html
  end
end
