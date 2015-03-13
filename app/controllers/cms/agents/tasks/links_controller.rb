class Cms::Agents::Tasks::LinksController < ApplicationController
  public
    def check
      @task.log "# #{@site.name}"

      @site_url = @site.full_url

      check_url @site_url
    end

    def check_url(url)
      @task.log url

      if @site_url[0] == "/" || url.index(@site_url) == 0
        url  = url.sub(/^#{@site_url}/, "/")

        file = "#{@site.path}#{url}"
        file = File.join(file, "index.html") if Fs.directory?(file)
        file = nil unless Fs.file?(file)

        dump file
      end
    end
end
