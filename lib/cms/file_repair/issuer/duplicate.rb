module Cms::FileRepair::Issuer
  class Duplicate < Base
    def check_duplicates
      delete_duplicates(deletes: false)
    end

    def delete_duplicates(deletes: true)
      @issues = []
      @fixes = []
      return if html.blank?
      return if !body.respond_to?(:files) || body.files.blank?

      file_urls = html.scan(/"(\/fs\/.+?)"/).flatten
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
        if deletes
          file.destroy
          add_fixes("重複元 #{ref}", file.id, file.url)
        else
          add_issue("重複元 #{ref}", file.id, file.url)
        end
      end
    end

    class << self
      def header
        %w(ID タイトル ステータス 公開画面 管理画面 ファイルID ファイルURL エラー)
      end
    end
  end
end
