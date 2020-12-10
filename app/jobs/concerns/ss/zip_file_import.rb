module SS::ZipFileImport
  extend ActiveSupport::Concern

  def perform(temp_file_id)
    @cur_file = SS::File.find(temp_file_id)

    import_file
  ensure
    if @cur_file && @cur_file.model == 'ss/temp_file'
      @cur_file.destroy
    end
  end

  module ClassMethods
    def import_from_zip(file, bindings = {})
      require 'zip'
      require 'nkf'
      Zip::File.open(file) do |archive|
        archive.each do |entry|
          uploaded_file = ::Fs::UploadedFile.new("ss_file")
          begin
            uploaded_file.binmode
            uploaded_file.write(entry.get_input_stream.read)
            uploaded_file.rewind
            uploaded_file.original_filename = NKF.nkf('-w', entry.name)
            uploaded_file.content_type = 'text/csv'

            temp_file = SS::TempFile.new
            temp_file.in_file = uploaded_file
            temp_file.save!
          ensure
            uploaded_file.close
          end

          self.bind(bindings).perform_now(temp_file.id)
        end
      end
    end
  end

  private

  def import_file
    # sub class must override this method
    raise NotImplementedError
  end

  def open_csv_table(opts = {})
    if Fs.mode == :file
      table = ::CSV.read(@cur_file.path, **opts)
      yield table
    else
      Tempfile.create('csv') do |file|
        ::File.binwrite(file.path, ::Fs.binread(@cur_file.path))
        table = ::CSV.read(file.path, **opts)
        yield table
      end
    end
  end
end
