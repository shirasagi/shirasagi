class Gws::Share::FoldersController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter

  model Gws::Share::Folder

  private

  def set_crumbs
    @crumbs << [t("modules.gws/share"), gws_share_files_path]
    @crumbs << [t("mongoid.models.gws/share/folder"), gws_share_folders_path]
  end

  def fix_params
    { cur_user: @cur_user, cur_site: @cur_site }
  end

  def pre_params
    p = super
    p[:readable_member_ids] = [@cur_user.id]
    @skip_default_group = true
    p
  end

  public

  def index
    @items = @model.site(@cur_site).
      allow(:read, @cur_user, site: @cur_site).
      search(params[:s]).
      page(params[:page]).per(50)
  end

  def download_folder
    ss_file_items = SS::File.where(folder_id: params[:id].to_i, deleted: nil)

    download_root_dir = "/tmp/shirasagi_download"
    download_dir = "#{download_root_dir}" + "/" + "#{@cur_user.id}_#{SecureRandom.hex(4)}"

    Dir.glob("#{download_root_dir}" + "/" + "#{@cur_user.id}_*").each do |tmp_dir|
      FileUtils.rm_rf(tmp_dir) if File.exists?(tmp_dir)
    end

    FileUtils.mkdir_p(download_dir) unless FileTest.exist?(download_dir)

    filenames = []
    ss_file_items.each {|item| filenames.push(item.name)}
    filename_duplicate_flag = filenames.size == filenames.uniq.size ? 0 : 1

    ss_file_items.each do |item|
      if  filename_duplicate_flag == 0
        FileUtils.copy("#{item.path}", "#{download_dir}" + "/" + "#{item.name}") if File.exist?(item.path)
      elsif filename_duplicate_flag == 1
        FileUtils.copy("#{item.path}", "#{download_dir}" + "/" + item._id.to_s + "_" + "#{item.name}") if File.exist?(item.path)
      end
    end

    @zipfile = download_dir + "/" + Time.now.strftime("%Y-%m-%d_%H-%M-%S") + ".zip"

    Zip::File.open(@zipfile, Zip::File::CREATE) do |zip_file|
      Dir.glob("#{download_dir}/*").each do |downloadfile|
        zip_file.add(NKF::nkf('-sx --cp932',File.basename(downloadfile)), downloadfile)
      end
    end

    send_file(@zipfile, type: 'application/zip', filename: File.basename(@zipfile), disposition: 'attachment')

    file_body = Class.new do
      attr_reader :to_path

      def initialize(path)
        @to_path = path
      end

      def each
        File.open(to_path, 'rb') do |file|
          while chunk = file.read(16384)
            yield chunk
          end
        end
      end

      def close
        FileUtils.rm_rf File.dirname(@to_path)
      end
    end
    self.response_body = file_body.new(@zipfile)

  end

end
