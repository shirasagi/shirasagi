class Cms::PostalCode::ImportBase < Cms::ApplicationJob
  def perform(temp_file_id)
    @cur_file = SS::TempFile.find(temp_file_id)

    import_file
  ensure
    @cur_file.destroy
  end

  class << self
    def import_from_zip(file)
      require 'zipruby'
      Zip::Archive.open(file) do |ar|
        ar.each do |f|
          uploaded_file = ::Fs::UploadedFile.new("ss_file")
          begin
            uploaded_file.binmode
            uploaded_file.write(f.read)
            uploaded_file.rewind
            uploaded_file.original_filename = f.name
            uploaded_file.content_type = 'text/csv'

            temp_file = SS::TempFile.new
            temp_file.in_file = uploaded_file
            temp_file.save!
          ensure
            uploaded_file.close
          end

          self.perform_now(temp_file.id)
        end
      end
    end
  end
end
