module Cms::Page::SequencedFilename
  extend ActiveSupport::Concern

  included do
    attr_accessor :skip_validate_seq_filename

    validate :validate_seq_filename, if: ->{ filename_changed? && basename =~ /^\d+(\.html)?$/ && !@skip_validate_seq_filename }
    before_save :seq_filename, if: ->{ basename.blank? }
  end

  private

  def validate_filename
    super unless basename.blank? && @basename.blank?
  end

  def validate_seq_filename
    if basename.sub(/\.html$/, '').to_i > current_sequence(:id)
      errors.add :basename, :unsafe_numeric_filename
    end
  end

  def seq_filename
    self.filename = dirname ? "#{dirname}#{id}.html" : "#{id}.html"
  end
end
