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

  def warmup_page(page)
    if page.site_id.present?
      page.site = id_site_map[page.site_id]
    end
    if page.layout_id.present?
      page.layout = id_layout_map[page.layout_id]
    end
    if page.try(:user_id).present?
      page.user = id_user_map[page.user_id]
    end
    if page.try(:form_id).present?
      page.form = id_form_map[page.form_id]
    end
    if page.try(:master_id).present?
      page.master = id_page_map[page.master_id]
    end
    if page.try(:thumb_id).present? && id_file_map.key?(page.thumb_id)
      page.thumb = id_file_map[page.thumb_id]
    end
    if page.try(:contact_group_id).present?
      page.contact_group = id_group_map[page.contact_group_id]
    end
    if page.try(:contact_group_id).present?
      page.contact_group = id_group_map[page.contact_group_id]
    end
    if page.try(:column_values).present?
      page.column_values.each do |column_value|
        column_value.column = id_column_map[column_value.column_id.to_s]
        if column_value.try(:file_id).present?
          column_value.file = id_file_map[column_value.file_id]
        end
      end
    end
  end

  def id_site_map
    @id_site_map ||= Cms::Site.all.to_a.index_by(&:id)
  end

  def id_layout_map
    @id_layout_map ||= Cms::Layout.all.site(@site).to_a.index_by(&:id)
  end

  def id_group_map
    @id_group_map ||= Cms::Group.all.site(@site).to_a.index_by(&:id)
  end

  def id_user_map
    @id_user_map ||= Cms::User.all.site(@site).to_a.index_by(&:id)
  end

  def id_form_map
    @id_form_map ||= Cms::Form.all.site(@site).to_a.index_by(&:id)
  end

  def id_column_map
    @id_column_map ||= Cms::Column::Base.all.site(@site).to_a.index_by { |column| column.id.to_s }
  end

  def id_page_map
    @id_page_map ||= begin
      criteria = Cms::Page.all.site(@site)
      criteria.only(:_id, :site_id, :layout_id, :name, :filename, :depth, :redirect_link).to_a.index_by(&:id)
    end
  end

  def id_file_map
    @id_file_map ||= begin
      id_page_map

      criteria = SS::File.all.in(owner_item_id: @id_page_map.keys)
      criteria = criteria.only(:_id, :name, :filename, :content_type, :site, :owner_item_type, :owner_item_id)
      criteria.to_a.index_by(&:id)
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
          warmup_page(page)
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
