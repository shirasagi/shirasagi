class Cms::Page::MoveJob < Cms::ApplicationJob
  include Job::SS::TaskFilter

  MODEL_CLASSES = [ Cms::Page, Cms::Part, Cms::Layout ].freeze

  self.task_name = "cms:move_pages"

  def perform(opts = {})
    opts = opts.symbolize_keys
    @src = opts[:src]
    @dst = opts[:dst]
    @site ||= site
    @user ||= user

    move
  end

  private

  def move
    @task.log "# #{@site.name}"
    @task.total_count = 0

    each_item do |item|
      @task.count
      @task.log item.full_url

      replace_html_fields(item)
      replace_array_fields(item)
      replace_column_values(item)
      next if !item.changed?

      item.cur_site = @site
      item.cur_user = @user
      item.history_backup_action = 'replace_urls'
      if item.save
        @task.log "success"
      else
        @task.log "error: " + item.errors.full_messages.join(', ')
      end
    end
  end

  def each_item(&block)
    or_conds = []
    or_conds += Cms::ApiFilter::Contents::HTML_FIELDS.map { |field| { field => /#{::Regexp.escape(@src)}/ } }
    or_conds += Cms::ApiFilter::Contents::CONTACT_FIELDS.map { |field| { field => /#{::Regexp.escape(@src)}/ } }
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

    MODEL_CLASSES.each do |klass|
      criteria = klass.site(@site).where("$or" => or_conds)
      all_ids = criteria.distinct(:id)

      @task.log "## #{klass.model_name.human}"
      @task.total_count += all_ids.size

      all_ids.each_slice(20) do |ids|
        klass.site(@site).in(id: ids).to_a.each(&block)
      end

      @task.log "#{all_ids.size.to_s(:delimited)} items loaded"
    end
  end

  def replace_html_fields(item)
    Cms::ApiFilter::Contents::HTML_FIELDS.each do |k|
      value = item.try(k)
      next if value.blank?

      value = replace_string_urls(value)
      item.send("#{k}=", value)
    end
    unless item.try(:contact_group_related?)
      Cms::ApiFilter::Contents::CONTACT_FIELDS.each do |k|
        value = item.try(k)
        next if value.blank?

        value = replace_string_urls(value)
        item.send("#{k}=", value)
      end
    end
  end

  def replace_array_fields(item)
    Cms::ApiFilter::Contents::ARRAY_FIELDS.each do |k|
      value = item.try(k)
      next if value.blank?

      value = replace_array_urls(value)
      item.send("#{k}=", value)
    end
  end

  def replace_column_values(item)
    return if item.try(:column_values).blank?

    column_values = item.column_values
    column_values.collect! do |column_value|
      case column_value._type
      when 'Cms::Column::Value::Free'
        column_value.value = replace_string_urls(column_value.value)
        column_value.contains_urls = replace_array_urls(column_value.contains_urls)
      when 'Cms::Column::Value::UrlField'
        column_value.value = replace_string_urls(column_value.value)
      when 'Cms::Column::Value::UrlField2', 'Cms::Column::Value::FileUpload'
        column_value.link_url = replace_string_urls(column_value.link_url)
      end
      column_value
    end
    item.column_values = column_values
  end

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
