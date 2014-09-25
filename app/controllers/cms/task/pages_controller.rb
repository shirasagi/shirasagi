# coding: utf-8
class Cms::Task::PagesController < ApplicationController
  include Cms::ReleaseFilter::Page

  public
    def release(opts)
      @task = opts[:task]
      @site = opts[:site]

      @task.log "# #{@site.name}"

      time = Time.now
      cond = [
        { state: "ready", release_date: { "$lte" => time } },
        { state: "public", close_date: { "$lte" => time } }
      ]

      pages = Cms::Page.site(@site).or(cond)
      @task.total_count = pages.size

      pages.each do |page|
        page = page.becomes_with_route
        @task += 1
        @task.log page.full_url

        if page.public?
          page.state = "closed"
          page.close_date = nil
        elsif page.state == "ready"
          page.state = "public"
          page.release_date = nil
        end

        next if page.save
        puts "error: " + page.errors.full_messages.join(', ')
      end
    end

    def generate(opts)
      @task = opts[:task]
      @site = opts[:site]

      @task.log "# #{@site.name}"
      #return unless @cur_site.serve_static_file?

      pages = Cms::Page.site(@site).public
      @task.total_count = pages.size

      pages.each do |page|
        @task += 1
        next unless page.public_node?
        if generate_page page.becomes_with_route
          @task.log page.url
        end
      end
    end

    def generate_with_node(opts)
      @task = opts[:task]
      @site = opts[:site]

      @task.log "# #{@site.name}"
      #return unless @cur_site.serve_static_file?

      pages = Cms::Page.site(@site).node(opts[:node]).public
      @task.total_count = pages.size

      pages.each do |page|
        @task += 1
        next unless page.public_node?
        if generate_page page.becomes_with_route
          @task.log page.url
        end
      end
    end

    def remove(opts)
      @task = opts[:task]
      @site = opts[:site]

      pages = Cms::Page.site(@site)
      @task.total_count = pages.size

      pages.each do |page|
        @task += 1
        if Fs.rm_rf page.path
          @task.log page.path
        end
      end
    end
end
