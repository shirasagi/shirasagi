class Cms::Agents::Tasks::PagesController < ApplicationController
  include Cms::PublicFilter::Page

  public
    def generate
      @task.log "# #{@site.name}"

      pages = Cms::Page.site(@site).public
      pages = pages.node(@node) if @node
      @task.total_count = pages.size

      pages.each do |page|
        @task.count
        @task.log page.url if page.becomes_with_route.generate_file
      end
    end

    def update
      @task.log "# #{@site.name}"

      pages = Cms::Page.site(@site).public
      pages = pages.node(@node) if @node

      pages.each do |page|
        page = page.becomes_with_route
        if !page.update
          @task.log page.url
          @task.log page.errors.full_messages.join("/")
        end
      end
    end

    def release
      @task.log "# #{@site.name}"

      time = Time.now
      cond = [
        { state: "ready", release_date: { "$lte" => time } },
        { state: "public", close_date: { "$lte" => time } }
      ]

      pages = Cms::Page.site(@site).or(cond)
      @task.total_count = pages.size

      pages.each do |page|
        @task.count
        @task.log page.full_url
        release_page page.becomes_with_route
      end
    end

    def release_page(page)
      if page.public?
        page.state = "closed"
        page.close_date = nil
      elsif page.state == "ready"
        page.state = "public"
        page.release_date = nil
      end

      if !page.save
        @task.log "error: " + page.errors.full_messages.join(', ') if @task
      end
    end

    def remove
      pages = Cms::Page.site(@site)
      @task.total_count = pages.size

      pages.each do |page|
        @task.count
        @task.log page.path if Fs.rm_rf page.path
      end
    end
end
