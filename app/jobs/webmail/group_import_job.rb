class Webmail::GroupImportJob < Webmail::ApplicationJob
  def put_log(message)
    Rails.logger.info(message)
    puts message
  end

  def perform(*args)
    temp_file_id = args.shift
    @cur_file = SS::File.find(temp_file_id)

    importer = Webmail::GroupExport::Importer.new
    importer.cur_user = user.webmail_user
    importer.in_file = @cur_file
    importer.import_csv

    if importer.errors.present?
      importer.errors.each do |error|
        put_log(error.full_message)
      end
    end
  ensure
    if @cur_file && @cur_file.model == 'ss/temp_file'
      @cur_file.destroy
    end
  end
end
