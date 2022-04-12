class Guide::Importer
  include ActiveModel::Model
  include SS::PermitParams
  include Cms::SitePermission
  include Cms::CsvImportBase
  include Guide::Importer::Procedure
  include Guide::Importer::Question
  include Guide::Importer::Transition

  set_permission_name "guide_procedures"

  attr_accessor :cur_site, :cur_node, :cur_user, :in_file

  permit_params :in_file

  private

  def validate_import
    if in_file.blank?
      errors.add(:base, I18n.t('ss.errors.import.blank_file'))
      return
    end

    if ::File.extname(in_file.original_filename).casecmp(".csv") != 0
      errors.add(:base, I18n.t('ss.errors.import.invalid_file_type'))
      return
    end

    unless self.class.valid_csv?(in_file, max_read_lines: 1)
      errors.add(:base, I18n.t('ss.errors.import.invalid_file_type'))
      return
    end

    true
  end

  def edge_headers
    @edge_headers ||= begin
      headers = @row.headers.map { |v| v.scan(/^(#{I18n.t("guide.transition")}(\d+))$/) }.flatten(1)
      headers = headers.map { |v, idx| (idx.to_i > 0) ? [v, (idx.to_i - 1)] : nil }.compact
      headers
    end
  end

  def explanation_headers
    @explanation_headers ||= begin
      headers = @row.headers.map { |v| v.scan(/^(#{I18n.t("guide.explanation")}(\d+))$/) }.flatten(1)
      headers = headers.map { |v, idx| (idx.to_i > 0) ? [v, (idx.to_i - 1)] : nil }.compact
      headers
    end
  end

  def encode_sjis(str)
    str.encode("SJIS", invalid: :replace, undef: :replace)
  end
end
