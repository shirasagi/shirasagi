class Gws::Affair::CapitalYear::Importer::Base
  include ActiveModel::Model

  attr_accessor :cur_site, :cur_user, :year
  attr_accessor :in_file
  attr_reader :year, :imported

  def model
    Gws::Affair::LeaveSetting
  end

  def encode_sjis(str)
    str.encode("SJIS", invalid: :replace, undef: :replace)
  end

  def validate_import
    return errors.add :in_file, :blank if in_file.blank?
    return errors.add :cur_site, :blank if cur_site.blank?
    return errors.add :cur_user, :blank if cur_user.blank?
    return errors.add :year, :blank if year.blank?

    fname = in_file.original_filename
    unless /^\.csv$/i.match?(::File.extname(fname))
      errors.add :in_file, :invalid_file_type
      return
    end

    begin
      CSV.read(in_file.path, headers: true, encoding: 'SJIS:UTF-8')
      in_file.rewind
    rescue => e
      errors.add :in_file, :invalid_file_type
    end
  end
end
