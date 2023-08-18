class SS::Migration20211011000000
  include SS::Migration::Base

  depends_on "20210825000000"

  def change
    SS::File.where(model: "cms/import_file").each do |file|
      job_file = Cms::ImportJobFile.where(file_ids: file.id).first
      next if job_file

      file.destroy
    end
  end
end
