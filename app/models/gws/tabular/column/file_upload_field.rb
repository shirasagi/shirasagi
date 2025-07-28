class Gws::Tabular::Column::FileUploadField < Gws::Column::Base
  include Gws::Addon::Tabular::Column::FileUploadField
  include Gws::Addon::Tabular::Column::Base

  self.use_unique_state = false

  field :export_state, type: String, default: 'none'
  field :allowed_extensions, type: SS::Extensions::Words

  permit_params :export_state, :allowed_extensions

  before_validation :normalize_allowed_extensions

  validates :export_state, inclusion: { in: %w(none public), allow_blank: true }

  def export_state_options
    %w(none public).map do |v|
      [ I18n.t("gws/tabular.options.export_state.#{v}"), v ]
    end
  end

  def store_as_in_file
    "col_#{id}_id"
  end

  def configure_file(file_model)
    store_as = store_as_in_file
    field_name = store_as.sub("_id", "")

    file_model.belongs_to_file field_name, accepts: allowed_extensions
    if required?
      file_model.validates field_name, presence: true
    end
    case index_state
    when 'asc', 'enabled'
      file_model.index store_as => 1
    when 'desc'
      file_model.index store_as => -1
    end

    if export_state == "public"
      file_model.after_save do
        site = self.cur_site || self.site
        file = read_tabular_value(field_name)
        if site && file
          if Gws::Tabular.public_file?(self)
            Gws.publish_file(site, file)
          else
            Gws.depublish_file(site, file)
          end
        end
      rescue => e
        Rails.logger.warn { "#{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}" }
      end

      file_model.after_destroy do
        site = self.cur_site || self.site
        file = read_tabular_value(field_name)
        if site && file
          Gws.depublish_file(site, file)
        end
      rescue => e
        Rails.logger.warn { "#{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}" }
      end
    end

    file_model.renderer_factory_map[field_name] = method(:value_renderer)
  end

  def value_renderer(value, type, **options)
    Gws::Tabular::Column::FileUploadFieldComponent.new(value: value, type: type, column: self, **options)
  end

  def to_csv_value(item, db_value, **_options)
    return if db_value.blank?
    "#{item.id}/#{db_value.id}_#{db_value.filename}"
  end

  def write_csv_value(item, zip_entry, locale: nil)
    unless zip_entry
      # CSVインポート時、一括して添付ファイルを削除することもできるが、一括削除はフレーミングを発生させやすいので、
      # 添付ファイルの一括削除はさせない。
      # item.public_send("col_#{id}=", nil)
      return
    end

    basename = ::File.basename(::SS::Zip.safe_zip_entry_name(zip_entry))
    underscore_pos = basename.index("_")
    if underscore_pos
      file_id = basename[0..underscore_pos - 1]
    end
    if file_id.present? && file_id.numeric?
      # basenameの先頭にIDが付加されているので除去する
      basename = basename[file_id.length + 1..-1]
    end

    file = ::SS::File.create_from_zip_entry!(zip_entry, basename: basename) if zip_entry
    item.public_send("col_#{id}=", file)
  end

  private

  def normalize_allowed_extensions
    return if self.allowed_extensions.blank?

    self.allowed_extensions = self.allowed_extensions.
      map(&:strip).
      reject(&:blank?).
      map do |ext|
        ext = ext.downcase
        ext.start_with?(".") ? ext : ".#{ext}"
      end.
      uniq
  end
end
