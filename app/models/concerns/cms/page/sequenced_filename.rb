module Cms::Page::SequencedFilename
  extend ActiveSupport::Concern

  included do
    before_save :seq_filename, if: ->{ basename.blank? }
  end

  private
    def validate_filename
      super unless basename.blank? && @basename.blank?
    end

    def seq_filename
      self.filename = dirname ? "#{dirname}#{id}.html" : "#{id}.html"
    end
end
