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

  def each_page(&block)
    criteria = Cms::Page.site(@site).and_public
    criteria = criteria.node(@node) if @node
    all_ids = criteria.pluck(:id)
    @task.total_count = all_ids.size

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
          page = page.becomes_with_route
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
        page = page.becomes_with_route
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
      { state: "ready", release_date: { "$lte" => time } },
      { state: "public", close_date: { "$lte" => time } }
    ]

    pages = Cms::Page.site(@site).or(cond)
    ids   = pages.pluck(:id)
    @task.total_count = ids.size

    ids.each do |id|
      rescue_with(rescue_p: rescue_p) do
        @task.count
        page = Cms::Page.site(@site).or(cond).where(id: id).first
        next unless page
        @task.log page.full_url
        release_page page.becomes_with_route
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
        page.delete
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

  def move
    @task.log "# #{@site.name}"
    @task.total_count = 0

    or_conds = []
    or_conds += Cms::ApiFilter::Contents::HTML_FIELDS.map { |field| { field => /=\"#{::Regexp.escape(@src)}/ } }
    or_conds += Cms::ApiFilter::Contents::ARRAY_FIELDS.map { |field| { field => /\A#{::Regexp.escape(@src)}/ } }
    or_conds << {
      column_values: {
        "$elemMatch" => {
          "$or" => Cms::ApiFilter::Contents::COLUMN_VALUES_FIELDS.map do |key|
            { key => { "$in" => [/#{::Regexp.escape(@src)}/] } }
          end
        }
      }
    }

    [Cms::Page, Cms::Part, Cms::Layout].each do |klass|
      criteria = klass.site(@site).where("$and" => [{ "$or" => or_conds }])
      all_ids = criteria.distinct(:id)

      @task.log "## #{klass.model_name.human}"
      @task.total_count += all_ids.size

      all_ids.each_slice(20) do |ids|
        klass.site(@site).in(id: ids).each do |item|
          @task.count
          attr = {}

          item = item.becomes_with_route if item.try(:route)

          Cms::ApiFilter::Contents::HTML_FIELDS.each do |k|
            next if item.try(k).blank?

            attr[k] = replace_string_urls(item.send(k))
            item[k] = attr[k]
          end
          Cms::ApiFilter::Contents::ARRAY_FIELDS.each do |k|
            next if item.try(k).blank?

            attr[k] = replace_array_urls(item.send(k))
            item[k] = attr[k]
          end
          if item.try(:column_values).present?
            column_values = item.column_values
            column_values.collect! do |column_value|
              case column_value._type
              when 'Cms::Column::Value::Free'
                column_value.value = replace_string_urls(column_value.value)
                column_value.contains_urls = replace_array_urls(column_value.contains_urls)
              when 'Cms::Column::Value::UrlField'
                column_value.value = replace_string_urls(column_value.value)
              when 'Cms::Column::Value::UrlField2'
                column_value.link_url = replace_string_urls(column_value.link_url)
              end
              column_value
            end
            item.column_values = column_values
          end

          next if !item.changed?

          @task.log item.full_url
          item.cur_site = @site
          item.cur_user = @user
          item.history_backup_action = 'replace_urls'
          if !item.save
            @task.log "error: " + item.errors.full_messages.join(', ')
          end
        end
      end
    end
  end

  private

  def replace_string_urls(string)
    return string if string.blank?

    string.gsub(@src, @dst)
  end

  def replace_array_urls(array)
    return array if array.blank?

    array.collect do |v|
      v.sub(@src, @dst)
    end
  end
end
