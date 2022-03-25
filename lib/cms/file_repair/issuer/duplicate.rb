module Cms::FileRepair::Issuer
  class Duplicate < Base
    def check_duplicates
      @issues = []
      @fixes = []
      delete_duplicates(false)
    end

    def delete_duplicates(delete = true)
      @issues = []
      @fixes = []
      return if !body.respond_to?(:file_ids)
      return if !body.respond_to?(:files)
      return if html.blank?
      return if body.files.blank?

      file_urls = html.scan(/\"(\/fs\/.+?)\"/).flatten
      return if file_urls.blank?

      delete_files = {}
      body.files.each do |lf|
        next if delete_files[lf.id]

        body.files.each do |rf|
          next if lf.id == rf.id
          next if delete_files[rf.id]
          next if file_urls.include?(rf.url)
          next if !same_file?(lf, rf)
          delete_files[rf.id] = [rf, lf.id]
        end
      end
      delete_files.values.each do |file, ref|
        if delete
          file.destroy
          add_fixes("重複元 #{ref}", file.id, file.url)
        else
          add_issue("重複元 #{ref}", file.id, file.url)
        end
      end
    end

    public

    class << self
      def header
        %w(ID タイトル ステータス 公開画面 管理画面 ファイルID ファイルURL エラー)
      end
    end
  end
end
