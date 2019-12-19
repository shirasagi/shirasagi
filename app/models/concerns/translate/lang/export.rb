module Translate::Lang::Export
  extend ActiveSupport::Concern

  included do
    attr_accessor :in_file
    permit_params :in_file
  end

  def import_csv
    validate_import_file
    return false unless errors.empty?

    no = 0
    each_csv do |row|
      no += 1

      code = row[t(:code)]
      item = self.class.find_or_initialize_by(site_id: cur_site.id, code: code)
      item.name = row[t(:name)]
      item.google_translation_code = row[t(:google_translation_code)]
      item.microsoft_translator_text_code = row[t(:microsoft_translator_text_code)]
      item.mock_code = row[t(:mock_code)]
      item.accept_languages = row[t(:accept_languages)]
      item.save

      errors.add :base, "##{no} " + item.errors.full_messages.join("\n") if item.errors.present?
    end

    errors.empty?
  end

  private

  def each_csv(&block)
    csv = ::CSV.read(in_file.path, headers: true, encoding: 'SJIS:UTF-8')
    csv.each(&block)
  end

  def validate_import_file
    return errors.add :in_file, :blank if in_file.blank?

    fname = in_file.original_filename
    unless /^\.csv$/i.match?(::File.extname(fname))
      errors.add :in_file, :invalid_file_type
      return
    end

    begin
      no = 0
      each_csv do |row|
        no += 1
        # check csv record up to 100
        break if no >= 100
      end
      in_file.rewind
    rescue => e
      errors.add :in_file, :invalid_file_type
    end
  end

  module ClassMethods
    def encode_sjis(str)
      str.encode("SJIS", invalid: :replace, undef: :replace)
    end

    def csv_headers
      %w(code name google_translation_code microsoft_translator_text_code mock_code accept_languages).map { |v| t(v) }
    end

    def enum_csv
      criteria = self.all
      Enumerator.new do |y|
        y << encode_sjis(csv_headers.to_csv)
        criteria.each do |item|
          line = []
          line << item.code
          line << item.name
          line << item.google_translation_code
          line << item.microsoft_translator_text_code
          line << item.mock_code
          line << item.accept_languages.join("\n")
          y << encode_sjis(line.to_csv)
        end
      end
    end
  end
end
