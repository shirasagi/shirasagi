class Cms::SyntaxChecker::Column::FilesAltPresenceChecker
  include ActiveModel::Model
  include Cms::SyntaxChecker::Column::Base

  attr_accessor :context, :content, :column_value, :attribute, :params

  def check
    return unless parsed_params

    labels = column_value[attribute] || {}
    column_value.files.each do |file|
      next if labels[file.id.to_s].present?

      message = I18n.t("errors.messages.blank_file_label", filename: file.name)
      context.errors << Cms::SyntaxChecker::CheckerError.new(
        context: context, content: content, code: nil, checker: self, error: message)
    end
  end
end
