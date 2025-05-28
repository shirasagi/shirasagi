class Webmail::GroupExport::Exporter < Webmail::GroupExport::Base

  attr_accessor :items, :encoding

  def enum_csv(options = {})
    @encoding = options[:encoding].presence || "Shift_JIS"

    I18n.with_locale(I18n.default_locale) do
      Enumerator.new do |y|
        y << header_csv
        items.each do |item|
          item.imap_settings.each_with_index do |setting, i|
            line = EXPORT_DEF.map do |export_def|
              export_field(item, i, setting, export_def)
            end
            y << line_csv(line)
          end
        end
      end
    end
  end

  def enum_template_csv(options = {})
    @encoding = options[:encoding].presence || "Shift_JIS"

    I18n.with_locale(I18n.default_locale) do
      Enumerator.new do |y|
        y << header_csv
        items.each do |item|
          setting = OpenStruct.new
          line = EXPORT_DEF.map do |export_def|
            export_field(item, 0, setting, export_def)
          end
          y << line_csv(line)
        end
      end
    end
  end

  def header_csv
    if @encoding == "Shift_JIS"
      EXPORT_DEF.map { |export_def| encode_sjis(export_def[:label]) }.to_csv
    else
      SS::Csv::UTF8_BOM + EXPORT_DEF.map { |export_def| export_def[:label] }.to_csv
    end
  end

  def line_csv(line)
    if @encoding == "Shift_JIS"
      line.map { |v| encode_sjis(v.to_s) }.to_csv
    else
      line.to_csv
    end
  end

  def content_type
    "text/csv; charset=#{@encoding}"
  end

  def encode_sjis(str)
    return str if str.blank?
    str.encode("SJIS", invalid: :replace, undef: :replace)
  end

  def export_field(item, index, setting, export_def)
    getter = export_def[:getter]
    if getter.nil?
      method = "get_item_#{export_def[:key].tr(".", "_")}".to_sym
      getter = method if respond_to?(method, true)
    end
    if getter.nil?
      getter = method(:get_item_field).curry.call(export_def[:key])
    end

    if getter.is_a?(Symbol)
      return if getter == :none
      send(getter, item, index, setting)
    else
      getter.call(item, index, setting)
    end
  end

  private

  def get_item_field(field_name, item, index, setting)
    val = item
    field_name.split(".").each do |f|
      if f == "imap_setting"
        val = setting
      else
        val = val.send(f)
      end
      break if val.nil?
    end

    return if val.nil?

    if val.is_a?(Date) || val.is_a?(Time)
      return I18n.l(val)
    end

    val.to_s
  end

  def get_item_imap_setting_account_index(item, index, setting)
    index + 1
  end

  def get_item_imap_setting_imap_ssl_use(item, index, setting)
    setting.imap_ssl_use.present? ? I18n.t("webmail.options.imap_ssl_use.#{setting.imap_ssl_use}") : nil
  end

  def get_item_imap_setting_default(item, index, setting)
    index == item.imap_default_index ? index + 1 : nil
  end
end
