module SS::ExportHelper
  extend ActiveSupport::Concern

  def sanitize_filename(filename)
    filename.gsub(/[\<\>\:\"\/\\\|\?\*]/, '_').slice(0..60)
  end
end
