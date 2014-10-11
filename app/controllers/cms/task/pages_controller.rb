class Cms::Task::PagesController < ApplicationController
  include SS::Task::BaseFilter
  include Cms::ReleaseFilter::Page

  before_action :set_params

  private
    def set_params
      @site = params[:site]
      @node = params[:node]
    end

  public
    def generate
      task.log "# #{@site.name}"
      #return unless @cur_site.serve_static_file?

      pages = Cms::Page.site(@site).public
      pages = pages.node(@node) if @node
      task.total_count = pages.size

      pages.each do |page|
        task.count
        next unless page.public_node?

        if generate_page page.becomes_with_route
          task.log page.url
        end
      end
    end

    def release
      task.log "# #{@site.name}"

      time = Time.now
      cond = [
        { state: "ready", release_date: { "$lte" => time } },
        { state: "public", close_date: { "$lte" => time } }
      ]

      pages = Cms::Page.site(@site).or(cond)
      task.total_count = pages.size

      pages.each do |page|
        page = page.becomes_with_route
        task.count
        task.log page.full_url

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

    def remove
      pages = Cms::Page.site(@site)
      task.total_count = pages.size

      pages.each do |page|
        task.count
        if Fs.rm_rf page.path
          task.log page.path
        end
      end
    end
end
