class Cms::AllContentsMoves::CheckJob < Cms::ApplicationJob
  include Job::SS::TaskFilter

  self.task_class = Cms::Task
  self.task_name = "cms:all_contents_moves:check"

  PAGE_ID_HEADER = -> { I18n.t("all_content.page_id") }
  FILENAME_HEADER = -> { I18n.t("mongoid.attributes.cms/model/page.filename") }

  class << self
    def valid_csv?(file)
      I18n.with_locale(I18n.default_locale) do
        required_headers = [PAGE_ID_HEADER.call, FILENAME_HEADER.call]
        SS::Csv.valid_csv?(file, headers: true, required_headers: required_headers)
      end
    end
  end

  def perform(*args)
    ss_file_id = args.first

    file = SS::File.find(ss_file_id)
    result = check(file)

    # 中間生成物を保存
    FileUtils.mkdir_p(task.base_dir) if task.base_dir
    File.write("#{task.base_dir}/check_result.json", result.to_json) if task.base_dir

    task.log "Check completed: #{result[:rows].size} rows processed"
    task.log "  OK: #{result[:rows].count { |r| r[:status] == 'ok' }}"
    task.log "  Confirmation: #{result[:rows].count { |r| r[:status] == 'confirmation' }}"
    task.log "  Error: #{result[:rows].count { |r| r[:status] == 'error' }}"
  ensure
    file.destroy rescue nil
  end

  private

  def check(file)
    rows = []
    page_id_header = PAGE_ID_HEADER.call
    filename_header = FILENAME_HEADER.call

    SS::Csv.foreach_row(file, headers: true) do |row, index|
      row_data = {
        "id" => nil,
        "filename" => nil,
        "destination_filename" => nil,
        "status" => "error",
        "errors" => [],
        "confirmations" => []
      }

      # CSVの全データを保持
      row.each do |key, value|
        row_data[key.to_s] = value
      end

      page_id = row[page_id_header].to_s.strip
      destination_filename = row[filename_header].to_s.strip

      row_data["id"] = page_id
      row_data["destination_filename"] = destination_filename

      # ページIDのチェック
      if page_id.blank?
        row_data["errors"] << I18n.t("cms.all_contents_moves.errors.page_id_blank")
        rows << row_data
        next
      end

      unless BSON::ObjectId.legal?(page_id)
        row_data["errors"] << I18n.t("cms.all_contents_moves.errors.invalid_page_id")
        rows << row_data
        next
      end

      # ページの取得
      page = Cms::Page.site(site).where(id: page_id).first
      if page.blank?
        row_data["errors"] << I18n.t("cms.all_contents_moves.errors.page_not_found")
        rows << row_data
        next
      end

      row_data["filename"] = page.filename
      row_data["title"] = page.name

      # 移動先ファイル名のチェック
      if destination_filename.blank?
        row_data["errors"] << I18n.t("cms.all_contents_moves.errors.destination_filename_blank")
        rows << row_data
        next
      end

      # 拡張子のチェックと補完
      unless destination_filename.end_with?(".html")
        destination_filename = "#{destination_filename}.html"
        row_data["destination_filename"] = destination_filename
      end

      # 移動元と移動先が同じかチェック
      if page.filename == destination_filename
        row_data["errors"] << I18n.t("cms.all_contents_moves.errors.same_filename")
        rows << row_data
        next
      end

      # 差し替えページのチェック
      if page.respond_to?(:branch?) && page.branch?
        row_data["errors"] << I18n.t("cms.all_contents_moves.errors.branch_page_can_not_move")
        rows << row_data
        next
      end

      # ページの移動権限チェック
      page.cur_site = site
      page.cur_user = user
      unless page.allowed?(:move, user, site: site)
        row_data["errors"] << I18n.t("cms.all_contents_moves.errors.no_move_permission")
        rows << row_data
        next
      end

      # バリデーション実行
      page.validate_destination_filename(destination_filename)
      if page.errors.present?
        row_data["errors"] += page.errors.full_messages
        rows << row_data
        next
      end

      # ロックチェック
      if page.respond_to?(:locked?) && page.locked?
        row_data["errors"] << I18n.t("cms.all_contents_moves.errors.page_locked", user: page.lock_owner.long_name)
        rows << row_data
        next
      end

      # 公開状態チェック
      if page.state == "public"
        dst_dir = ::File.dirname(destination_filename).sub(/^\.$/, "")
        if dst_dir.present?
          dst_parent = Cms::Node.site(site).where(filename: dst_dir).first
          if dst_parent
            # 親フォルダーとその祖先がすべて公開かチェック
            unless all_parents_public?(dst_parent)
              row_data["errors"] << I18n.t("cms.all_contents_moves.errors.destination_folder_not_public")
              rows << row_data
              next
            end
          end
        end
      end

      # リンク影響確認
      linking_pages = Cms.contains_urls(page, site: site)
      if linking_pages.present?
        row_data["status"] = "confirmation"
        linking_pages.each do |linking_page|
          if linking_page.is_a?(Cms::Node)
            row_data["confirmations"] << { "type" => "node", "id" => linking_page.id }
          elsif linking_page.is_a?(Cms::Page)
            row_data["confirmations"] << { "type" => "page", "id" => linking_page.id }
          elsif linking_page.is_a?(Cms::Layout)
            row_data["confirmations"] << { "type" => "layout", "id" => linking_page.id }
          elsif linking_page.is_a?(Cms::Part)
            row_data["confirmations"] << { "type" => "part", "id" => linking_page.id }
          end
        end
      else
        row_data["status"] = "ok"
      end

      rows << row_data
    end

    {
      rows: rows,
      task_id: task.id,
      created_at: Time.zone.now.iso8601
    }
  end

  def all_parents_public?(node)
    return false unless node.state == "public"

    if node.parent
      all_parents_public?(node.parent)
    else
      true
    end
  end
end

