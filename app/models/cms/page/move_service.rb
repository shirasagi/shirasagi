class Cms::Page::MoveService
  include ActiveModel::Model

  attr_accessor :cur_site, :cur_user, :page, :destination

  # trueの場合、移動後のURL置換ジョブ（Cms::Page::MoveJob）をキューイングしない。
  # 一括移動ジョブから呼ばれる場合に使用し、全移動完了後にまとめてURL置換を行う。
  attr_accessor :skip_replace_urls_job

  validate :validate_move

  def move
    return false if invalid?

    @src_url = page.url.dup
    page.cur_node = nil
    page.filename = destination
    page.basename = nil

    if page.is_a?(Cms::Addon::EditLock)
      page.remove_attribute(:lock_owner_id) if page.has_attribute?(:lock_owner_id)
      page.remove_attribute(:lock_until) if page.has_attribute?(:lock_until)
    end

    result = page.save
    unless result
      SS::Model.copy_errors(page, self)
      return false
    end

    move_branch_page if page.is_a?(Workflow::Addon::Branch)

    if result && SS.config.cms.replace_urls_after_move && !skip_replace_urls_job
      Cms::Page::MoveJob.bind(site_id: cur_site, user_id: cur_user)
        .perform_later(src: @src_url, dst: page.url)
    end

    result
  end

  # 移動元と移動先のURL情報（一括移動でのURL置換用）
  def url_mappings
    return nil unless @src_url
    { src: @src_url, dst: page.url }
  end

  def find_referencing_contents
    return [] unless page.is_a?(Cms::Model::Page)
    return [] if page.try(:branch?)

    results = []

    Cms::Page.site(cur_site).and_linking_pages(page).each do |p|
      results << { type: "page", id: p.id, name: p.name, filename: p.filename }
    end

    Cms::Layout.site(cur_site).where(html: /#{::Regexp.escape(page.url)}/).each do |l|
      results << { type: "layout", id: l.id, name: l.name, filename: l.filename }
    end

    Cms::Part.site(cur_site).where(html: /#{::Regexp.escape(page.url)}/).each do |p|
      results << { type: "part", id: p.id, name: p.name, filename: p.filename }
    end

    results
  end

  private

  def validate_move
    validate_destination_filename
    return if errors.present?

    validate_permissions
    validate_branch_page
    validate_edit_lock
    validate_published_to_closed_folder
  end

  def validate_destination_filename
    if destination.blank?
      errors.add :base, I18n.t('cms.all_contents_moves.errors.invalid_filename_chars')
      return
    end

    if destination !~ /^([\w\-]+\/)*[\w\-]+(#{::Regexp.escape(page.send(:fix_extname))})?$/
      errors.add :base, I18n.t('cms.all_contents_moves.errors.invalid_filename_chars')
      return
    end

    if page.filename == destination
      errors.add :base, I18n.t('cms.all_contents_moves.errors.same_filename')
      return
    end

    validate_destination_node
    validate_destination_conflicts
  end

  def validate_destination_node
    dst_dir = ::File.dirname(destination).sub(/^\.$/, "")
    return if dst_dir.blank?

    dst_node = Cms::Node.site(cur_site).where(filename: dst_dir).first
    if dst_node.blank?
      errors.add :base, I18n.t('cms.all_contents_moves.errors.not_found_parent_node')
      return
    end

    unless dst_node.allowed?(:read, cur_user, site: cur_site)
      errors.add :base, I18n.t('cms.all_contents_moves.errors.not_have_move_permission')
    end
  end

  def validate_destination_conflicts
    if Cms::Page.site(cur_site).ne(id: page.id).where(filename: destination).first
      errors.add :base, I18n.t('mongoid.errors.messages.taken')
    end

    if Fs.exist?("#{cur_site.path}/#{destination}")
      errors.add :base, I18n.t('mongoid.errors.models.cms/model/node.exist_physical_file')
    end
  end

  def validate_permissions
    unless page.allowed?(:move, cur_user, site: cur_site)
      errors.add :base, I18n.t('cms.all_contents_moves.errors.not_have_move_permission')
    end
  end

  def validate_branch_page
    if page.respond_to?(:branch?) && page.branch?
      errors.add :base, I18n.t('cms.all_contents_moves.errors.branch_page_can_not_move')
    end
  end

  def validate_edit_lock
    if page.is_a?(Cms::Addon::EditLock) && page.locked?
      errors.add :base, I18n.t('cms.all_contents_moves.errors.locked')
    end
  end

  def validate_published_to_closed_folder
    return unless page.public?

    dst_dir = ::File.dirname(destination).sub(/^\.$/, "")
    return if dst_dir.blank?

    parts = dst_dir.split("/")
    parts.length.times do |i|
      ancestor_path = parts[0..i].join("/")
      ancestor_node = Cms::Node.site(cur_site).where(filename: ancestor_path).first
      next unless ancestor_node

      unless ancestor_node.public?
        errors.add :base, I18n.t('cms.all_contents_moves.errors.destination_folder_not_public')
        return
      end
    end
  end

  def move_branch_page
    branch_page = page.branches.first
    return unless branch_page

    branch_page.cur_site = cur_site
    branch_page.cur_user = cur_user
    branch_dst = ::File.join(::File.dirname(destination), branch_page.basename)
    branch_page.cur_node = nil
    branch_page.filename = branch_dst
    branch_page.basename = nil

    if branch_page.is_a?(Cms::Addon::EditLock)
      branch_page.remove_attribute(:lock_owner_id) if branch_page.has_attribute?(:lock_owner_id)
      branch_page.remove_attribute(:lock_until) if branch_page.has_attribute?(:lock_until)
    end

    branch_page.save
  end
end
