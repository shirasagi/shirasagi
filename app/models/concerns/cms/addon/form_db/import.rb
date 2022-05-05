module Cms::Addon::FormDb::Import
  extend ActiveSupport::Concern
  extend SS::Addon

  PAGE_DELETE_LIMIT = 40.hours.freeze

  included do
    field :import_url, type: String
    field :import_primary_key, type: String
    field :import_page_name, type: String
    field :import_column_options, type: SS::Extensions::ArrayOfHash, default: []
    field :import_map, type: Integer
    field :pippi_import_category, type: Integer

    has_many :import_logs, class_name: 'Cms::FormDb::ImportLog', dependent: :destroy

    permit_params :import_url, :import_primary_key, :import_page_name, :import_map
    permit_params :pippi_import_category
    permit_params import_column_options: [:name, :kind, :values]

    validates :import_url, format: /\Ahttps?:\/\//, if: -> { import_url.present? }
    validate :validate_import_import_column_options
  end

  def validate_import_import_column_options
    self.import_column_options = import_column_options.map do |idx, option|
      name = option['name']
      kind = option['kind'].presence || 'any_of'
      values = option['values'].to_s.split(/\R/).compact
      (name.present? && values.present?) ? { name: name, kind: kind, values: values } : nil
    end.compact
  end

  def search_kind_options
    %w(any_of start_with end_with none_of).map { |v| [ I18n.t("ss.options.search.kind.#{v}"), v ] }
  end

  def import_csv(options = {})
    @task = options[:task]

    if options[:file].blank?
      errors.add(:base, :invalid_csv) if in_file.blank?
      return false if errors.present?
    end
    csv_file = options[:file].presence || in_file

    if import_primary_key.present?
      primary_column = form.columns.entries.find { |col| col.name == import_primary_key }
      unless primary_column
        errors.add :base, 'invalid primary key column'
        return false
      end
    end

    SS::Csv.foreach_row(csv_file.path, headers: true) do |csv_row|
      params = csv_row.to_hash

      if import_column_options.present?
        result = import_column_options.all? do |option|
          value = params[option['name']].to_s

          case option['kind']
          when 'start_with'
            value.start_with?(option['values'].first.to_s)
          when 'end_with'
            value.end_with?(option['values'].first.to_s)
          when 'none_of'
            option['values'].none?(value)
          else # 'any_of'
            option['values'].any?(value)
          end
        end
        next unless result
      end

      page_name = params[import_page_name.presence || Article::Page.t(:name)]
      next unless page_name.present?

      if import_primary_key.present?
        condition = search_column_condition(primary_column, params[import_primary_key])
        item = Article::Page.site(site).node(node).where(condition).first
      else
        item = Article::Page.site(site).node(node).where(form_id: form_id, name: page_name).first
      end

      item ||= Article::Page.new(cur_site: site, cur_user: @cur_user, cur_node: node)

      item.name = page_name
      item.map_points = validate_row_map_points(params) if import_map
      item.category_ids = pippi_validate_row_category_ids(params) if pippi_import_category
      item.state = 'public'

      item_changed = item.changed?

      if save_page(item, params)
        if @task
          flag = item_changed ? "更新" : "----"
          @task.log("#{flag}: #{item.id} #{item.name}")
        end
      else
        message = "#{item.id} #{item.name}" + item.errors.full_messages.join('/')
        errors.add :base, message
        @task.log(message) if @task
      end
    end

    delete_conditions = { updated: { '$lt': Time.zone.now.ago(PAGE_DELETE_LIMIT) } }
    Article::Page.site(site).node(node).where(form_id: form_id).where(delete_conditions).each do |item|
      if item.destroy && @task
        @task.log("削除: #{item.id} #{item.name}")
      end
    end

    errors.blank?
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

  def validate_row_map_points(row)
    return [] if row['緯度'].blank? || row['経度'].blank?

    [{ name: '', loc: [row['経度'], row['緯度']], text: '', image: '' }]
  end

  def pippi_validate_row_category_ids(row)
    case row['カテゴリー']
    when 'イベント'
      category_name = '体験・ワークショップ'
    when 'スポーツ'
      category_name = 'スポーツ'
    when '講座・教室'
      category_name = '教室・セミナー'
    when 'おんがく'
      category_name = '文化芸術'
    when 'そうだん'
      category_name = '相談'
    when 'こそだて'
      if row['イベント名'].start_with?('ブックスタート', 'もぐもぐ元気っこ教室', '離乳食教室')
        category_name = '教室・セミナー'
      elsif %w(浜松こども館 浜松科学館みらいーら 青少年の家).include?(row['連絡先名称'])
        category_name = '体験・ワークショップ'
      else
        category_name = 'その他'
      end
    else
      category_name = 'その他'
    end

    Category::Node::Base.site(site).where(filename: /event\//).only(:id, :name).select do |node|
      [row['区'], row['場所名称'], category_name].include?(node.name)
    end.collect(&:id)
  end

  def trauncate_import_logs
    import_logs.order(created: -1).skip(30).destroy_all
  end
end
