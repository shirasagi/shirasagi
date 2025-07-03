class Gws::Tabular::File::CsvImporter
  include ActiveModel::Model

  attr_accessor :site, :user, :user_group, :space, :release, :path_or_io, :zip_archive, :zip_basedir

  def call
    if user.respond_to?(:cur_site=)
      user.cur_site ||= site
    end

    i = 0
    succeeded_count = 0
    failed_count = 0
    each_csv do |row|
      i += 1

      Rails.logger.tagged("#{i.to_fs(:delimited)}行目") do
        id = value(row, :id)
        item = find_item(id) if id.present? && BSON::ObjectId.legal?(id)
        if item
          # already existed.
          # in this case, check whether item is updatable or not
          set_item_defaults(item)
          unless importable_item?(item)
            Rails.logger.warn { "インポートすることができません。" }
            next
          end
        end
        item ||= begin
          # create new item
          item = model.new
          set_item_defaults(item)
          set_workflow_destination_defaults(item)
          item
        end

        importer.import_row(row, item)
        unless item_after_import_row(item)
          failed_count += 1
          item_import_failed(item)
          next
        end

        result = item.save
        if result
          succeeded_count += 1
          item_import_succeeded(item)
        else
          failed_count += 1
          item_import_failed(item)
        end
      end
    end
  ensure
    import_finished(succeeded_count, failed_count)
  end

  private

  def model
    @model ||= Gws::Tabular::File[release]
  end

  def released_form
    @released_form ||= begin
      form = Gws::Tabular.released_form(release, site: site)
      form || release.form
    end
  end

  def released_columns
    @released_columns ||= begin
      columns = Gws::Tabular.released_columns(release, site: site)
      columns || released_form.columns.reorder(order: 1, id: 1).to_a
    end
  end

  def each_csv(&block)
    I18n.with_locale(I18n.default_locale) do
      SS::Csv.foreach_row(path_or_io, headers: true, &block)
    end
  end

  def importer
    @importer ||= begin
      SS::Csv.draw(:import, context: self, model: model) do |importer|
        define_importer_basic(importer)
        define_importer_columns(importer)
        if released_form.workflow_enabled?
          define_importer_workflow(importer)
        end
        define_importer_tail(importer)
      end.create
    end
  end

  delegate :to_array, :from_label, to: SS::Csv::CsvImporter

  def value(row, key)
    key = model.t(key) if key.is_a?(Symbol)
    row[key].try(:strip)
  end

  def define_importer_basic(_importer)
    # importer.simple_column :id
  end

  def define_importer_columns(importer)
    released_columns.each do |column|
      next if column.is_a?(Gws::Tabular::Column::LookupField)

      if Gws::Tabular.i18n_column?(column)
        SS.each_locale_in_order do |lang|
          name = "#{column.name} (#{I18n.t("ss.options.lang.#{lang}")})"
          importer.simple_column "col_#{column.id}_#{lang}", name: name do |row, item, head, value|
            item.write_csv_value(column, value, locale: lang)
          end
        end
      elsif column.is_a?(::Gws::Tabular::Column::FileUploadField)
        importer.simple_column "col_#{column.id}", name: column.name do |row, item, head, value|
          set_file_upload_field(column, row, item, head, value)
        end
      else
        importer.simple_column "col_#{column.id}", name: column.name do |row, item, head, value|
          item.write_csv_value(column, value, locale: I18n.default_locale)
        end
      end
    end
  end

  def define_importer_workflow(importer)
  end

  def define_importer_tail(_importer)
    # importer.simple_column :updated
  end

  def find_item(id)
    model.where(user_id: user.id, id: id).first
  end

  def set_item_defaults(item)
    item.site = item.cur_site = site
    item.cur_user = user
    item.space = item.cur_space = space
    item.form = item.cur_form = released_form
    item
  end

  def importable_item?(item)
    if item.user_id != user.id
      Rails.logger.info { "この行は#{item.user_i18n_name}のアイテムを更新しようとしています。他人のアイテムは更新することができません。" }
      return false
    end

    true
  end

  def set_workflow_destination_defaults(item)
    return item if item.persisted?
    return item if !released_form.workflow_enabled?

    item.destination_group_ids = released_form.destination_group_ids
    item.destination_user_ids = released_form.destination_user_ids
    if item.destination_groups.active.present? || item.destination_users.active.present?
      item.destination_treat_state = "untreated"
    else
      item.destination_treat_state = "no_need_to_treat"
    end

    item
  end

  def set_file_upload_field(column, row, item, head, value)
    return if value.blank?

    unless zip_archive
      Rails.logger.info do
        <<~TEXT
          CSVファイルのインポートの場合、#{column.name}はインポートできません。
          CSVファイルと添付ファイルとを1つのZIPファイルに圧縮し、ZIPファイルをインポートしてください。
        TEXT
      end
      return
    end

    file_entry = find_file_entry(value, row)
    if file_entry&.file?
      item.write_csv_value(column, file_entry, locale: I18n.default_locale)
    else
      Rails.logger.warn { "#{column.name} に指定されているファイル #{value} がZIP内に見つかりませんでした。" }
    end
  end

  def find_file_entry(entry_path, row)
    return unless zip_archive

    search_paths = Enumerator.new do |y|
      y << entry_path
      y << "#{zip_basedir}/#{entry_path}" if zip_basedir

      base_path = ::File.basename(entry_path)
      y << base_path
      y << "#{zip_basedir}/#{base_path}" if zip_basedir

      id = value(row, :id)
      if id.present?
        y << "#{id}/#{base_path}"
        y << "#{zip_basedir}/#{id}/#{base_path}" if zip_basedir
      end
    end

    entry = nil
    search_paths.each do |path|
      entry = find_zip_entry(path)
      break if entry
    end

    entry
  end

  def find_zip_entry(path)
    return unless zip_archive

    @entry_map ||= begin
      map = {}
      zip_archive.each do |entry|
        next if entry.directory?

        entry_name = ::SS::Zip.safe_zip_entry_name(entry)
        entry_name = entry_name.downcase
        map[entry_name] = entry
      end
      map
    end

    @entry_map[path.downcase]
  end

  # rubocop:disable Naming/PredicateMethod
  def item_after_import_row(_item)
    true
  end
  # rubocop:enable Naming/PredicateMethod

  def item_import_succeeded(_item)
    Rails.logger.info { "インポートしました。" }
  end

  def item_import_failed(item)
    Rails.logger.warn do
      <<~TEXT
        インポートできませんでした。
        #{item.errors.full_messages.join("\n")}
      TEXT
    end
  end

  def import_finished(succeeded_count, failed_count)
    Rails.logger.info { "#{succeeded_count} 件成功、#{failed_count} 件失敗" }
  end
end
