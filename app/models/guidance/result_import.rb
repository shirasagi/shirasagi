module Guidance::ResultImport
  extend ActiveSupport::Concern

  included do
    attr_accessor :in_file

    permit_params :in_file
  end

  def import_csv
    validate_import_file
    return false unless errors.empty?

    each_csv do |row, no|
      no += 1

      id = row[t(:id)].presence
      name = row[t(:name)]

      item = self.class.where(site_id: cur_site.id, node_id: cur_node.id, id: id).first if id
      item ||= self.class.find_or_initialize_by(site_id: cur_site.id, node_id: cur_node.id, name: name)
      item.id = nil if item.new_record?
      item.name = row[t(:name)]
      item.order = row[t(:order)]
      item.text = row[t(:text)]
      item.condition_and = row[t(:condition_and)]
      item.condition_or1 = row[t(:condition_or1)]
      item.condition_or2 = row[t(:condition_or2)]
      item.condition_or3 = row[t(:condition_or3)]
      item.save

      SS::Model.copy_errors(item, self, prefix: "##{no} ") if item.errors.present?
    end

    errors.empty?
  end

  private

  def each_csv(&block)
    SS::Csv.foreach_row(in_file, headers: true, &block)
  end

  def validate_import_file
    return errors.add :in_file, :blank if in_file.blank?

    fname = in_file.original_filename
    unless /^\.csv$/i.match?(::File.extname(fname))
      errors.add :in_file, :invalid_file_type
      return
    end

    begin
      each_csv do |row, no|
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
      %w(id name order text condition_and condition_or1 condition_or2 condition_or3).map { |v| t(v) }
    end

    def enum_csv
      criteria = self.all
      Enumerator.new do |y|
        y << encode_sjis(csv_headers.to_csv)
        criteria.each do |item|
          line = []
          line << item.id
          line << item.name
          line << item.order
          line << item.text
          line << item.condition_and.join("\n")
          line << item.condition_or1.join("\n")
          line << item.condition_or2.join("\n")
          line << item.condition_or3.join("\n")
          y << encode_sjis(line.to_csv)
        end
      end
    end
  end
end
