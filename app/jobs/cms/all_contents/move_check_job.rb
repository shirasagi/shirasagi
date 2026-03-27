class Cms::AllContents::MoveCheckJob < Cms::ApplicationJob
  include Job::SS::TaskFilter

  self.task_class = Cms::Task
  self.task_name = "cms:all_contents_moves"

  def perform(temp_file_id)
    file = SS::TempFile.find(temp_file_id)
    results = []
    index = 0

    Cms::AllContentsMoveValidator.each_csv(file) do |row|
      row_number = index + 2
      result = check_row(row, row_number)
      results << result
      task.log "#{result[:status]}: row #{result[:row]} id=#{result[:id]}"
      task.count
      index += 1
    end

    save_check_result(results)
  ensure
    file&.destroy rescue nil
  end

  private

  def check_row(row, row_number)
    page_id = row[I18n.t('cms.all_contents_moves.csv_headers.page_id')]&.to_i
    destination = row[I18n.t('cms.all_contents_moves.csv_headers.filename')]

    page = Cms::Page.site(site).where(id: page_id).first
    unless page
      return build_error(row, row_number, page_id, destination, [I18n.t('cms.all_contents_moves.errors.page_not_found')])
    end

    page.cur_site = site
    page.cur_user = user

    service = Cms::Page::MoveService.new(
      cur_site: site, cur_user: user,
      page: page, destination: destination
    )

    if service.valid?
      result = build_ok(row, row_number, page, destination)

      confirmations = service.find_referencing_contents
      if confirmations.present?
        result[:status] = "confirmation"
        result[:confirmations] = confirmations
      end

      result
    else
      build_error(row, row_number, page.id, destination, service.errors.full_messages)
    end
  end

  def build_ok(row, row_number, page, destination)
    headers = I18n.t('cms.all_contents_moves.csv_headers')
    {
      row: row_number,
      id: page.id,
      filename: page.filename,
      destination: destination,
      name: row[headers[:name]],
      index_name: row[headers[:index_name]],
      layout: row[headers[:layout]],
      order: row[headers[:order]],
      keywords: row[headers[:keywords]],
      description: row[headers[:description]],
      summary_html: row[headers[:summary_html]],
      category_names: row[headers[:category]],
      parent_crumb_urls: row[headers[:parent_crumb_urls]],
      contact_state: row[headers[:contact_state]],
      contact_group_name: row[headers[:contact_group_name]],
      contact_group: row[headers[:contact_group]],
      contact_group_contact: row[headers[:contact_group_contact]],
      contact_charge: row[headers[:contact_charge]],
      contact_tel: row[headers[:contact_tel]],
      contact_fax: row[headers[:contact_fax]],
      contact_email: row[headers[:contact_email]],
      contact_postal_code: row[headers[:contact_postal_code]],
      contact_address: row[headers[:contact_address]],
      contact_link_url: row[headers[:contact_link_url]],
      contact_link_name: row[headers[:contact_link_name]],
      contact_group_relation: row[headers[:contact_group_relation]],
      contact_sub_group_names: row[headers[:contact_sub_groups]],
      group_names: row[headers[:group_ids]],
      status: "ok"
    }
  end

  def build_error(row, row_number, page_id, destination, error_messages)
    {
      row: row_number,
      id: page_id,
      filename: destination,
      status: "error",
      errors: error_messages
    }
  end

  def save_check_result(results)
    dir = task.base_dir
    FileUtils.mkdir_p(dir) unless ::Dir.exist?(dir)
    path = ::File.join(dir, "check_result.json")
    ::File.write(path, results.to_json)
  end
end
