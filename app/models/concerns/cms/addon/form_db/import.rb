module Cms::Addon::FormDb::Import
  extend ActiveSupport::Concern
  extend SS::Addon

  PAGE_DELETE_LIMIT = 40.hours.freeze

  included do
    field :import_url, type: String
    field :import_url_hash, type: String
    field :import_primary_key, type: String
    field :import_page_name, type: String
    field :import_column_options, type: SS::Extensions::ArrayOfHash, default: []
    field :import_exclude_columns, type: SS::Extensions::Lines
    field :import_event, type: Integer
    field :import_map, type: Integer
    field :import_skip_same_file, type: Integer
    field :generate_on_import, type: Integer

    has_many :import_logs, class_name: 'Cms::FormDb::ImportLog', dependent: :destroy

    permit_params :import_url, :import_primary_key, :import_page_name, :import_exclude_columns,
      :import_event, :import_map, :import_skip_same_file, :generate_on_import
    permit_params import_column_options: [:name, :kind, :values]

    validates :import_url, format: /\Ahttps?:\/\//, if: -> { import_url.present? }
    validate :validate_import_import_column_options, if: -> { import_column_options.dig(0, 1) }
  end

  def validate_import_import_column_options
    self.import_column_options = import_column_options.map do |idx, option|
      next if option.blank?

      name = option['name']
      kind = option['kind'].presence || 'any_of'
      values = option['values'].to_s.split(/\R/).compact
      (name.present? && values.present?) ? { name: name, kind: kind, values: values } : nil
    end.compact
  end

  def search_kind_options
    %w(any_of none_of start_with end_with include_any_of include_none_of).map do |v|
      [ I18n.t("ss.options.search.kind.#{v}"), v ]
    end
  end

  def import_csv(options = {})
    @task = options[:task] # import_url
    manually = options[:manually] == 1 # import_url on the web
    started = Time.zone.now
    delete_limit = started #.ago(PAGE_DELETE_LIMIT)

    csv_file = options[:file].presence || in_file
    return add_import_error(I18n.t('errors.messages.invalid_csv')) if csv_file.blank?

    csv_hash = Digest::MD5.file(csv_file.path).to_s
    if import_skip_same_file == 1 && @task && !manually && import_url_hash == csv_hash
      @task.log I18n.t('errors.messages.form_db_same_file')
      return true
    end

    page_name_key = import_page_name.presence || Article::Page.t(:name)
    primary_column = resolve_import_primary_column
    return false if errors.present?

    SS::Csv.foreach_row(csv_file.path, headers: true) do |csv_row|
      params = csv_row.to_hash
      summary = csv_row.to_s.slice(0..30)
      next unless import_column_options_match?(params)

      page_name = params[page_name_key].to_s.gsub(/[\r\n]+/, ' ').strip
      if page_name.blank?
        add_import_error I18n.t('errors.messages.form_db_column_not_found', column: page_name_key, summary: summary)
        next
      end

      params.except!(*import_exclude_columns) if import_exclude_columns.present?

      if import_primary_key.present?
        condition = search_column_condition(primary_column, params[import_primary_key])
        item = Article::Page.site(site).node(node).where(condition).first
      else
        item = Article::Page.site(site).node(node).where(form_id: form_id, name: page_name).first
      end

      item ||= Article::Page.new(cur_site: site, cur_user: @cur_user, cur_node: node)
      item_new_record = item.new_record?
      item.name = page_name

      import_row_events(item, params) if import_event == 1
      import_row_map_points(item, params) if import_map == 1

      if generate_on_import != 1
        def item.serve_static_file?
          false
        end
      end

      set_page_attributes(item, params)

      if !item.changed?
        item.set(imported: started)
        @task.log("-------: #{item.id} #{item.name}") if @task
        next
      end

      item.imported = started
      if item.save
        flag = item_new_record ? "created" : "updated"
        @task.log("#{flag}: #{item.id} #{item.name}") if @task
      else
        add_import_error("#{item.name} " + item.errors.full_messages.join('/'))
      end

      # end foreach_row
    end

    # if @task
    #   @task.log("[Sync] delete before '#{I18n.l(delete_limit)}'")
    #   criteria = Article::Page.site(site).node(node).where(form_id: form_id).where(imported: { '$lt': delete_limit })
    #   count = criteria.destroy_all
    #   @task.log("deleted: #{count} pages")
    # end
    self.set(import_url_hash: csv_hash)

    errors.blank?
  end

  def add_import_error(message)
    @task.log(message) if @task
    errors.add :base, message
    false
  end

  def resolve_import_primary_column
    return if import_primary_key.blank?

    primary_column = form.columns.entries.find { |col| col.name == import_primary_key }
    return primary_column if primary_column

    add_import_error(I18n.t('errors.messages.forn_db_invalid_primary_key'))
  end

  def search_column_condition(column, value)
    conditions = Cms::Extensions::ConditionForms.demongoize([
      {
        form_id: form.id,
        filters: [
          {
            column_id: column.id,
            condition_kind: 'any_of',
            condition_values: [value],
          },
        ]
      }
    ]).to_mongo_query

    if conditions.length == 1
      conditions.first
    elsif conditions.length > 1
      { "$and" => [{ "$or" => conditions }] }
    end
  end

  def import_column_options_match?(params)
    return true if import_column_options.blank?

    import_column_options.all? do |option|
      condition_match?(params[option['name']], option['kind'], option['values'])
    end
  end

  def condition_match?(value, kind, needles)
    value = value.to_s

    case kind
    when 'any_of'
      needles.any?(value)
    when 'none_of'
      needles.none?(value)
    when 'start_with'
      needles.any? { |v| value.start_with?(v) }
    when 'end_with'
      needles.any? { |v| value.end_with?(v) }
    when 'include_any_of'
      needles.any? { |v| value.include?(v) }
    when 'include_none_of'
      needles.none? { |v| value.include?(v) }
    else
      false
    end
  end

  def import_row_events(item, row)
    if row['開始日'].present? && (event_range = format_event_date(row['開始日'], row['終了日'])).present?
      recurrence = { kind: "date", start_at: event_range.first, frequency: "daily" }
      recurrence[:until_on] = event_range.last
      item.event_recurrences = [ recurrence ]
      close_date = event_range.last + 1.month
      item.close_date = close_date if close_date > Time.zone.now
    else
      item.event_dates = []
      item.close_date = nil
    end

    if row['参加申込終了日'].blank?
      item.event_deadline = nil
    elsif row['参加申込終了時間'].present?
      item.event_deadline = "#{row['参加申込終了日']} #{row['参加申込終了時間']}"
    else
      item.event_deadline = row['参加申込終了日']
    end
  end

  # returns:
  #   ("2022/06/01", "2022/06/30") => Date(2022/06/01)..Date(2022/06/30)
  #   ("2022/06/01", nil) => [ Date(2022/06/01) ]
  #   ("foo", "bar") => []
  def format_event_date(start_date, end_date)
    d1 = Date.parse(start_date) rescue nil
    d2 = Date.parse(end_date) rescue nil
    (d1 && d2) ? (d1..d2) : [d1, d2].compact
  end

  def import_row_map_points(item, row)
    lng = row['経度'].presence || row['lng'].presence
    lat = row['緯度'].presence || row['lat'].presence
    item.map_points = (lng && lat) ? [{ name: '', loc: [lng, lat], text: '', image: '' }] : []
  end

  def trauncate_import_logs
    import_logs.order(created: -1).skip(30).destroy_all
  end
end
