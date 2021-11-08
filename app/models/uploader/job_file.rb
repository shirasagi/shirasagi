class Uploader::JobFile
  extend SS::Translation
  include SS::Document
  include SS::SanitizerJobFile
  include SS::Reference::User
  include Cms::Reference::Site

  seqid :id
  field :path, type: String

  def basename
    path.to_s.sub(/.*\//, "")
  end

  def extname
    return "" unless path.to_s.include?('.')
    path.to_s.sub(/.*\W/, "")
  end

  def sanitizer_input_path
    filename = "#{SS.config.ss.sanitizer_file_prefix}_uploader_#{id}_#{created.to_i}#{::File.extname(basename)}"
    "#{Rails.root}/#{SS.config.ss.sanitizer_input}/#{filename}"
  end

  def sanitizer_save
    input_path = sanitizer_input_path
    FileUtils.rm_f(input_path) if FileTest.exist?(input_path)
    FileUtils.cp(path, input_path)
  end

  def sanitizer_restore_file(output_path)
    if output_path.end_with?('Report.txt')
      SS::UploadPolicy.sanitizer_overwrite_error_file(output_path)
      FileUtils.mv(output_path, "#{path}_sanitize_error.txt", force: true)
    else
      FileUtils.mv(output_path, path, force: true)
      ::Uploader::File.auto_compile(path)
    end
  end

  class << self
    def directory(path, target = nil)
      if target == 'descendant'
        all.where(path: /^#{::Regexp.escape(path)}\//)
      else
        all.where(path: /^#{::Regexp.escape(path)}\/[^\/]+$/)
      end
    end

    def new_job(bindings)
      @job_bindings = bindings
      @job_args = []
      self
    end

    def upload(path)
      uploader = self.new(@job_bindings)
      uploader.path = path.delete_prefix("#{Rails.root}/")
      uploader.save!
      uploader.sanitizer_save
      uploader
    end

    def bind_mkdir(paths)
      @job_args << { mkdir: paths.map { |p| p.delete_prefix("#{Rails.root}/") } }
      self
    end

    def bind_mv(src, dst)
      @job_args << { mv: [src.delete_prefix("#{Rails.root}/"), dst.delete_prefix("#{Rails.root}/")] }
      self
    end

    def bind_rm(paths)
      @job_args << { rm: paths.map { |p| p.delete_prefix("#{Rails.root}/") } }
      self
    end

    def bind_text(path, data)
      @job_args << { text: [path.delete_prefix("#{Rails.root}/"), data] }
      self
    end

    def save_job
      return if @job_args.empty?
      Uploader::FilesJob.bind(@job_bindings).perform_later(@job_args)
    end

    def sanitizer_restore(output_path)
      filename = ::File.basename(output_path)
      return unless /\A#{SS.config.ss.sanitizer_file_prefix}_uploader_\d+_/.match?(filename)

      id = filename.sub(/\A#{SS.config.ss.sanitizer_file_prefix}_uploader_(\d+).*/, '\\1').to_i
      job_model = self.find(id) rescue nil
      return unless job_model

      job_model.sanitizer_restore_file(output_path)
      job_model.destroy
      return job_model
    rescue => e
      Rails.logger.error("sanitizer_restore: #{e} (#{output_path})")
      return nil
    end
  end
end
