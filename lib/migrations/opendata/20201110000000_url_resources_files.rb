class SS::Migration20201110000000
  include SS::Migration::Base

  depends_on "20200630000000"

  def change
    ss_files = SS::File.where(model: "opendata/url_resource").index_by { |item| item.id }
    return if ss_files.blank?

    Opendata::Dataset.each do |dataset|
      next if dataset.url_resources.blank?

      dataset.url_resources.each do |url_resource|
        next if ss_files[url_resource.file_id].blank?

        ss_files.delete(url_resource.file_id)
      end
    end

    ss_files.each do |id, item|
      item.destroy
    end
  rescue => e
    Rails.logger.warn("#{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}")
  end
end
