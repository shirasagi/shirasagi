class Cms::Column::MultipleFilesUpload < Cms::Column::Base
  def alignment_options
    %w(flow).map { |v| [ I18n.t("cms.options.alignment.#{v}"), v ] }
  end

  def form_check_enabled?
    true
  end
end
