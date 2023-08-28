class Cms::Agents::Tasks::PagesController < ApplicationController
  include Cms::PublicFilter::Page
  include SS::RescueWith

  PER_BATCH = 100

  private

  def rescue_p
    proc do |exception|
      exception_backtrace(exception) do |message|
        @task.log message
        Rails.logger.error message
      end
    end
  end

  def filter_by_segment(ids)
    return ids if @segment.blank?

    keys = @site.generate_page_segments
    return ids if keys.blank?
    return ids if keys.index(@segment).nil?

    @task.log "# filter by #{@segment}"
    ids.select { |id| (id % keys.size) == keys.index(@segment) }
  end

  def each_page(&block)
    criteria = Cms::Page.site(@site).and_public
    criteria = criteria.node(@node) if @node
    all_ids = criteria.pluck(:id)
    @task.total_count = all_ids.size

    all_ids = filter_by_segment(all_ids)
    all_ids.each_slice(PER_BATCH) do |ids|
      criteria.in(id: ids).to_a.each(&block)
      @task.count(ids.length)
    end
  end

  def each_page_with_rescue(&block)
    each_page do |page|
      rescue_with(rescue_p: rescue_p) do
        yield page
      end
    end
  end

  public

  def generate
    @task.log "# #{@site.name}"
    @task.performance.header(name: "generate page performance log at #{Time.zone.now.iso8601}")
    @task.performance.collect_site(@site) do
      if @site.generate_locked?
        @task.log(@site.t(:generate_locked))
        return
      end

      each_page_with_rescue do |page|
        next unless page

        @task.performance.collect_page(page) do
          result = page.generate_file(release: false, task: @task)

          @task.log page.url if result
        end
      end
    end
  end

  def update
    @task.log "# #{@site.name}"

    pages = Cms::Page.site(@site)
    pages = pages.node(@node) if @node
    ids   = pages.pluck(:id)

    ids.each do |id|
      rescue_with(rescue_p: rescue_p) do
        page = Cms::Page.site(@site).where(id: id).first
        next unless page
        if !page.update
          @task.log page.url
          @task.log page.errors.full_messages.join("/")
        end
      end
    end
  end

  def release
    @task.log "# #{@site.name}"

    time = Time.zone.now
    cond = [
      # condition for pages to be public
      { state: "ready", release_date: { "$lte" => time } },
      # condition for pages to be closed
      { state: "public", close_date: { "$lte" => time } }
    ]

    pages = Cms::Page.site(@site).where("$or" => cond)
    ids   = pages.pluck(:id)
    @task.total_count = ids.size

    ids.each do |id|
      rescue_with(rescue_p: rescue_p) do
        @task.count
        page = Cms::Page.site(@site).where("$or" => cond).where(id: id).first
        next unless page
        @task.log page.full_url
        release_page page
      end
    end
  end

  def release_page(page)
    page.cur_site = @site

    if page.public?
      page.state = "closed"
      page.close_date = nil
    elsif page.state == "ready"
      page.state = "public"
      page.release_date = nil
    end

    if page.save
      if page.try(:branch?) && page.state == "public"
        page.skip_history_trash = true if page.respond_to?(:skip_history_trash)
        page.destroy
      end
    elsif @task
      @task.log "error: " + page.errors.full_messages.join(', ')
    end
  end

  def remove
    pages = Cms::Page.site(@site)
    @task.total_count = pages.size

    pages.order_by(id: 1).find_each(batch_size: PER_BATCH) do |page|
      rescue_with(rescue_p: rescue_p) do
        @task.count
        @task.log page.path if Fs.rm_rf page.path
      end
    end
  end
end
