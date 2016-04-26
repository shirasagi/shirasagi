module Sys::SiteCopyValid
  private
    def chk_copy_site
      if params["@copy"]["copy_site"].present?
        @site = Cms::Site.find(params["@copy"]["copy_site"])
        if @site.name.blank?
          @run_flag = 0
          @er_copy_site_mes = "存在しないサイトです。選択し直してください。"
        end
      else
        @run_flag = 0
        @er_copy_site_mes = "「複製するサイト」を選択してください。"
      end
    end

    def chk_name
      if params["@copy"]["name"].blank?
        @run_flag = 0
        @er_name_mes = "「サイト名」を入力してください。"
      end
    end

    def chk_host
      if params["@copy"]["host"].blank?
        @run_flag = 0
        @host_flag = 0
        @er_host_mes = "「ホスト名」を入力してください。"
      elsif Cms::Site.where(host: params["@copy"]["host"]).length > 0
        @run_flag = 0
        @host_flag = 0
        @er_host_mes = "入力したホスト名は既に使用しています。別のホスト名を入力してください。"
      elsif params["@copy"]["host"].length < 3
        @run_flag = 0
        @host_flag = 0
        @er_host_mes = "ホスト名は3文字以上で入力してください。"
      end
    end

    def chk_domains
      if params["@copy"]["domains"].blank?
        @run_flag = 0
        @domain_flag = 0
        @er_domains_mes = "「ドメイン」を入力してください。"
      elsif Cms::Site.where(domains: params["@copy"]["domains"]).length > 0
        @run_flag = 0
        @domain_flag = 0
        @er_domains_mes = "入力したドメインは既に使用しています。別のドメインを入力してください。"
      end
    end

    def chk_valid
      @run_flag = 1
      @host_flag = 1
      @domain_flag = 1
      @er_copy_site_mes = ''
      @er_name_mes = ''
      @er_host_mes = ''
      @er_domains_mes = ''

      chk_copy_site
      chk_name
      chk_host
      chk_domains

    end
end
