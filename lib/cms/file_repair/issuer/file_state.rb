module Cms::FileRepair::Issuer
  class FileState < Base
    def check_states
      @issues = []
      @fixes = []
      return if html.blank?
      return if !body.respond_to?(:file_ids)
      return if !body.respond_to?(:files)

      each_fs_files do |file_id, file_url, file|
        result = check_stage1(file_id, file_url, file)
        next unless result

        result = check_stage2(file_id, file_url, file)
        next unless result

        check_stage3(file_id, file_url, file)
      end
    end

    def fix_states
      @issues = []
      @fixes = []
      return if html.blank?
      return if !body.respond_to?(:file_ids)
      return if !body.respond_to?(:files)

      each_fs_files do |file_id, file_url, file|
        fix_file_ids(file_id, file_url, file)
      end
    end

    private

    # check issues
    ## ファイルが存在し、owner_item が正しく記事を参照しているか
    def check_stage1(file_id, file_url, file)
      if file.nil?
        add_issue("ss_file が存在しない", file_id, file_url)
        return false
      end
      if emtpy_file?(file)
        add_issue("private/files/ss_files ファイルが空", file_id, file_url)
        return false
      end

      owner_item = file.owner_item rescue nil
      if owner_item.nil?
        add_issue("owner_item が正しく設定されていない", file_id, file_url)
        return false
      end
      if !same_owner_item?(owner_item)
        add_issue("owner_item が別ページを参照している (#{file.owner_item.id})", file_id, file_url)
        return false
      end
      true
    end

    ## stage1 を前提とする：file_ids にファイルが含まれているか
    def check_stage2(file_id, file_url, file)
      if !body.file_ids.include?(file.id)
        add_issue("file_ids にファイルが含まれていない", file_id, file_url)
        return false
      end
      true
    end

    ## stage2 を前提とする：ファイルの属性（site, state）が正しいか
    def check_stage3(file_id, file_url, file)
      if file.site.nil? || file.site_id != page.site_id
        add_issue("site が設定されていない", file_id, file_url)
      end
      if page.state == "public" && file.state == "closed"
        add_issue("ページが公開状態だが、ファイルは非公開状態", file_id, file_url)
      end
      if page.state == "closed" && file.state == "public"
        add_issue("ページが非公開状態だが、ファイルは公開状態", file_id, file_url)
      end
      true
    end

    # fix issues
    ## file_ids を修復する
    def fix_file_ids(file_id, file_url, file)
      # ファイルが存在しなければ、修復不可
      return false if file.nil?

      # owner_item が存在しなければ、修復不可
      owner_item = file.owner_item rescue nil
      return false if owner_item.nil?

      # owner_item が別のページを参照している、修復不可
      return false if file.owner_item_id != page.id

      if body.file_ids.include?(file.id)
        # file_ids にファイルが含まれている

        if invalid_file_state?(file)
          # ファイルの属性（state, site）が不正、修正
          fix_file_state(file)
          add_fixes("ファイルの属性（state, site）が不正", file_id, file_url)
          return true
        else
          # 正常
          return false
        end
      else
        # file_ids にファイルが含まれていない、修正
        body.add_to_set(file_ids: file.id)
        fix_file_state(file)
        add_fixes("file_ids にファイルが含まれていない", file_id, file_url)
        return  true
      end
    end

    def fix_file_state(file)
      state = page.state
      site_id = page.site_id
      thumb = nil

      file.set(state: state, site_id: site_id)
      if file.image?
        thumb = file.thumb
        if thumb && thumb.respond_to?(:state)
          thumb.set(state: state, site_id: site_id)
        end
      end

      if state == "closed"
        Fs.rm_rf(file.public_path) if ::File.exist?(file.public_path)
        if thumb && thumb.respond_to?(:public_path) && ::File.exist?(thumb.public_path)
          Fs.rm_rf(thumb.public_path)
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
