#frozen_string_literal: true

class Gws::Tabular::File::ImportParam < SS::ImportParam
  attr_accessor :cur_form

  validate :validate_extname

  VALID_EXT_NAMES = %w(.csv .zip).freeze

  private

  def validate_extname
    return if in_file.blank?

    extname = ::File.extname(in_file.original_filename)
    extname = extname.downcase if extname
    unless VALID_EXT_NAMES.include?(extname)
      errors.add :in_file, :invalid
    end
  end
end
