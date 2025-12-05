class Cms::AllContentsMoves::CheckJob < Cms::ApplicationJob
  include Job::SS::TaskFilter

  self.task_class = Cms::Task
  self.task_name = "cms:all_contents_moves:check"

  PAGE_ID_HEADER = -> { I18n.t("all_content.page_id") }
  FILENAME_HEADER = -> { I18n.t("cms.all_contents_moves.destination_filename") }

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
    task.log "  OK: #{result[:rows].count { |r| r['status'] == 'ok' }}"
    task.log "  Confirmation: #{result[:rows].count { |r| r['status'] == 'confirmation' }}"
    task.log "  Error: #{result[:rows].count { |r| r['status'] == 'error' }}"
  ensure
    file.destroy rescue nil
  end

  private

  def check(file)
    rows = []
    page_id_header = PAGE_ID_HEADER.call
    filename_header = FILENAME_HEADER.call

    SS::Csv.foreach_row(file, headers: true) do |row, _index|
      row_data = process_csv_row(row, page_id_header, filename_header)
      rows << row_data
    end

    {
      rows: rows,
      task_id: task.id,
      created_at: Time.zone.now.iso8601
    }
  end

  def process_csv_row(row, page_id_header, filename_header)
    row_data = build_row_data(row, page_id_header, filename_header)
    return row_data if row_data["errors"].present?

    page_id = row_data["id"].to_i
    page = find_page(page_id)
    unless page
      row_data["errors"] << I18n.t("cms.all_contents_moves.errors.page_not_found")
      return row_data
    end

    row_data["filename"] = page.filename
    row_data["title"] = page.name

    destination_filename = normalize_destination_filename(row_data["destination_filename"])
    row_data["destination_filename"] = destination_filename

    validate_row(row_data, page, destination_filename)
    return row_data if row_data["errors"].present?

    check_linking_pages(row_data, page)
    row_data
  end

  def build_row_data(row, page_id_header, filename_header)
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

    page_id_raw = row[page_id_header].to_s.strip
    destination_filename = row[filename_header].to_s.strip

    row_data["id"] = page_id_raw
    row_data["destination_filename"] = destination_filename

    validate_page_id(row_data, page_id_raw)
    row_data
  end

  def validate_page_id(row_data, page_id_raw)
    if page_id_raw.blank?
      row_data["errors"] << I18n.t("cms.all_contents_moves.errors.page_id_blank")
      return
    end

    unless page_id_raw.numeric?
      row_data["errors"] << I18n.t("cms.all_contents_moves.errors.invalid_page_id")
      return
    end

    row_data["id"] = page_id_raw.to_i
  end

  def find_page(page_id)
    Cms::Page.site(site).where(id: page_id).first
  end

  def normalize_destination_filename(destination_filename)
    return destination_filename if destination_filename.end_with?(".html")

    "#{destination_filename}.html"
  end

  def validate_row(row_data, page, destination_filename)
    if destination_filename.blank?
      row_data["errors"] << I18n.t("cms.all_contents_moves.errors.destination_filename_blank")
      return
    end

    if page.filename == destination_filename
      row_data["errors"] << I18n.t("cms.all_contents_moves.errors.same_filename")
      return
    end

    if page.respond_to?(:branch?) && page.branch?
      row_data["status"] = "error"
      row_data["errors"] << I18n.t("cms.all_contents_moves.errors.branch_page_can_not_move")
      return
    end

    validate_page_permissions(row_data, page, destination_filename)
    return if row_data["errors"].present?

    check_public_state(row_data, page, destination_filename)
  end

  def validate_page_permissions(row_data, page, destination_filename)
    page.cur_site = site
    page.cur_user = user
    unless page.allowed?(:move, user, site: site)
      row_data["errors"] << I18n.t("cms.all_contents_moves.errors.no_move_permission")
      return
    end

    page.validate_destination_filename(destination_filename)
    if page.errors.present?
      row_data["errors"] += page.errors.full_messages
      return
    end

    if page.respond_to?(:locked?) && page.locked?
      lock_owner_name = page.lock_owner&.long_name || I18n.t("cms.all_contents_moves.errors.unknown_lock_owner")
      row_data["errors"] << I18n.t("cms.all_contents_moves.errors.page_locked", user: lock_owner_name)
    end
  end

  def check_public_state(row_data, page, destination_filename)
    return unless page.state == "public"

    dst_dir = ::File.dirname(destination_filename).sub(/^\.$/, "")
    return if dst_dir.blank?

    dst_parent = Cms::Node.site(site).where(filename: dst_dir).first
    return unless dst_parent

    return if all_parents_public?(dst_parent)

    row_data["errors"] << I18n.t("cms.all_contents_moves.errors.destination_folder_not_public")
  end

  def check_linking_pages(row_data, page)
    linking_pages = Cms.contains_urls(page, site: site)
    if linking_pages.present?
      row_data["status"] = "confirmation"
      linking_pages.each do |linking_page|
        confirmation_type = case linking_page
                            when Cms::Node
                              "node"
                            when Cms::Page
                              "page"
                            when Cms::Layout
                              "layout"
                            when Cms::Part
                              "part"
                            end
        row_data["confirmations"] << { "type" => confirmation_type, "id" => linking_page.id } if confirmation_type
      end
    elsif row_data["status"] != "confirmation"
      row_data["status"] = "ok"
    end
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
