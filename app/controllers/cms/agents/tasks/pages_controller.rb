class Cms::Agents::Tasks::PagesController < ApplicationController
  include Cms::PublicFilter::Page

  before_action :set_attachments, only: :generate
  PER_BATCH = 100

  private
    def set_attachments
      @attachments = (@attachments == "1")
    end

  public
    def generate
      @task.log "# #{@site.name}"

      pages = Cms::Page.site(@site).and_public
      pages = pages.node(@node) if @node
      ids   = pages.pluck(:id)
      @task.total_count = ids.size

      ids.each do |id|
        @task.count
        page = Cms::Page.site(@site).and_public.where(id: id).first
        next unless page
        page.serve_static_relation_files = @attachments
        @task.log page.url if page.becomes_with_route.generate_file
      end
    end

    def update
      @task.log "# #{@site.name}"

      pages = Cms::Page.site(@site)
      pages = pages.node(@node) if @node
      ids   = pages.pluck(:id)

      ids.each do |id|
        page = Cms::Page.site(@site).where(id: id).first
        next unless page
        page = page.becomes_with_route
        if !page.update
          @task.log page.url
          @task.log page.errors.full_messages.join("/")
        end
      end
    end

    def release
      @task.log "# #{@site.name}"

      time = Time.zone.now
      cond = [
        { state: "ready", release_date: { "$lte" => time } },
        { state: "public", close_date: { "$lte" => time } }
      ]

      pages = Cms::Page.site(@site).or(cond)
      ids   = pages.pluck(:id)
      @task.total_count = ids.size

      ids.each do |id|
        @task.count
        page = Cms::Page.site(@site).or(cond).where(id: id).first
        next unless page
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

      if page.save
        if page.try(:branch?) && page.state == "public"
          master = page.master
          page.delete
          master.remove_file
        end
      elsif @task
        @task.log "error: " + page.errors.full_messages.join(', ')
      end
    end

    def remove
      pages = Cms::Page.site(@site)
      @task.total_count = pages.size

      pages.order_by(id: 1).find_each(batch_size: PER_BATCH) do |page|
        @task.count
        @task.log page.path if Fs.rm_rf page.path
      end
    end
end
