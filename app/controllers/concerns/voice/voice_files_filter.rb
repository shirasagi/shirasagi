module Voice::VoiceFilesFilter
  extend ActiveSupport::Concern
  include Cms::BaseFilter
  include Cms::CrudFilter

  included do
    model Voice::VoiceFile
    navi_view "voice/main/navi"
    before_action :set_item, only: [:show, :edit, :update, :delete, :destroy, :file]
    before_action :set_search, only: [:index]
  end

  private
    def fix_params
      { cur_site: @cur_site }
    end

    def set_item
      @item = @model.site(@cur_site).find(params[:id])
      raise "403" unless @item
    end

    def set_search
      s = params[:s]
      if s.present?
        @s = s
        if s[:keyword].present?
          @keyword = s[:keyword]
        end
      end
    end

  public
    def new
      raise "404"
    end

    def create
      raise "404"
    end

    def edit
      raise "404"
    end

    def update
      raise "404"
    end

    def download
      raise "403" unless @model.allowed?(:read, @cur_user, site: @cur_site, node: @cur_node)

      @items = @model.site(@cur_site).
        search(@s).
        order_by(updated: -1)
      send_csv @items
    end

    def file
      unless @item.exists?
        head :not_found
        return
      end

      send_audio_file(@item.file)
    end

  private
    def send_csv(items)
      require "csv"

      csv = CSV.generate do |data|
        data << %w(URL Error Updated)
        items.each do |item|
          line = []
          line << item.url
          line << item.error
          line << item.updated.strftime("%Y-%m-%d %H:%m")
          data << line
        end
      end

      send_data csv.encode("SJIS"), filename: "voice_files_#{Time.now.to_i}.csv"
    end

    def send_audio_file(file)
      return unless file
      timestamp = Fs.stat(file).mtime

      response.headers["Content-Type"] = "audio/mpeg"
      response.headers["Last-Modified"] = CGI::rfc1123_date(timestamp)

      if Fs.mode == :grid_fs
        return send_data Fs.binread(file)
      end

      # x_sendfile requires a instance which implements 'to_path' method.
      # see: Rack::Sendfile#call(env)
      file = ::File.new(file) unless file.respond_to?(:to_path)
      send_file file, disposition: :inline, x_sendfile: true
    end
end
