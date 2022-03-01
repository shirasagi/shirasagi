class Cms::Form::ImportColumnsJob < Cms::ApplicationJob
  include Job::SS::TaskFilter

  self.task_class = Cms::Task
  self.task_name = "form:create_column_values"

  def perform(ss_file_id)
    @count_errors = 0
    file = SS::File.find(ss_file_id)
    import_csv(file)
  end

  private

  def put_log(message)
    if @task
      @task.log(message)
    else
      Rails.logger.info(message)
    end
  end

  def import_csv(file)
    SS::Csv.foreach_row(file, headers: true) do |row, i|
      csv_row_num = i + 2
      begin
        @row = row
        @model = get_column_model
        create_column_value
      rescue => e
        put_log("#{I18n.t("cms.row_error", row_num: csv_row_num)}: #{e}")
      end
    end
  end

  def get_column_model
    type = @row["基本情報:属性"]
    model = Cms::Column.route_options.find { |k, v| k.sub("標準機能/", "") == type }
    model[1].sub('/', '/column/').classify.constantize
  end

  def create_column_value
    column_value = @model.new(get_attrs)
    column_value.set_basic_attrs(basic_attrs)

    put_log("#{column_value.name}を作成しました。") if column_value.save!
  end

  def get_attrs
    case @model
    when Cms::Column::TextField
      get_text_field_attrs
    when Cms::Column::DateField
      get_date_field_attrs
    end
  end

  def basic_attrs
    {
      name: @row["基本情報:名前"], order: @row["基本情報:並び順"].to_i, tooltips: [@row["基本情報:ツールチップ"]],
      layout: @row["レイアウト"], site_id: site.id, form_id: node.id
    }
  end

  def get_text_field_attrs
    {
      max_length: @row["制約条件:最大長"].to_i, place_holder: @row["制約条件:プレースホルダー"],
      additional_attr: @row["制約条件:追加属性"], input_type: input_type
    }
  end

  def get_date_field_attrs
    {
      place_holder: @row["日付入力:プレースホルダー"], html_tag: @row["日付入力:HTMLタグ"], html_additional_attr: @row["日付入力:HTML追加属性"]
    }
  end

  def input_type
    case @row["一行入力:種類"]
    when "電話番号"
      "tel"
    when "メールアドレス"
      "email"
    else #テキスト
      "text"
    end
  end
end
