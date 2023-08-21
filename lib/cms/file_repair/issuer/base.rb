module Cms::FileRepair::Issuer
  class Base
    attr_accessor :site, :page, :body, :issues, :fixes

    def initialize(site, page, body)
      @site = site
      @page = page
      @body = body
      @issues = []
      @fixes = []
    end

    def html
      if body.is_a?(Cms::Column::Value::Free)
        body.value
      elsif body.class.include?(Cms::Model::Page) && body.respond_to?(:html)
        body.html
      else
        nil
      end
    end

    def page_private_full_url
      ::File.join(site.mypage_full_url, page.private_show_path)
    end

    def same_file?(lf, rf)
      return false if emtpy_file?(lf)
      return false if emtpy_file?(rf)
      return false if lf.name != rf.name
      return false if lf.filename != rf.filename
      return false if !::FileUtils.cmp(lf.path, rf.path)
      true
    end

    def add_issue(message, file_id, file_url)
      issues << { message: message, file_id: file_id, file_url: file_url }
    end

    def add_fixes(message, file_id, file_url)
      fixes << { message: message, file_id: file_id, file_url: file_url }
    end

    def issues_csv
      issues.map do |issue|
        [
          page.id,
          page.name,
          page.label(:state),
          page.full_url,
          page_private_full_url,
          issue[:file_id],
          (issue[:file_url] ? ::File.join(site.full_url, issue[:file_url]) : nil),
          issue[:message]
        ]
      end
    end

    def fixes_csv
      fixes.map do |issue|
        [
          page.id,
          page.name,
          page.label(:state),
          page.full_url,
          page_private_full_url,
          issue[:file_id],
          (issue[:file_url] ? ::File.join(site.full_url, issue[:file_url]) : nil),
          issue[:message]
        ]
      end
    end

    def emtpy_file?(file)
      return true if !::File.exist?(file.path)
      return true if ::File.binread(file.path, 20).blank?
      false
    end

    def invalid_file_state?(file)
      return true if page.state == "public" && file.state == "closed"
      return true if page.state == "closed" && file.state == "public"
      return true if page.site_id != file.site_id
      false
    end

    def same_owner_item?(owner_item)
      return false if owner_item.id != page.id
      return false if owner_item.class != page.class
      true
    end

    def each_fs_files
      file_urls = html.scan(/"(\/fs\/(.+?)\/_\/.+?)"/)
      file_urls.each do |file_url, file_id|
        file_id = file_id.delete("/").to_i
        file = SS::File.find(file_id) rescue nil
        yield(file_id, file_url, file)
      end
    end
  end
end
