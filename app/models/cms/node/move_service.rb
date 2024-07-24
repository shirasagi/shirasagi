class Cms::Node::MoveService
  include ActiveModel::Model

  attr_accessor :cur_site, :cur_user, :source, :parent_node, :basename, :confirm_changes

  validate :validate_basename

  def parent_node_id=(value)
    if value.present?
      self.parent_node = Cms::Node.site(cur_site).find(value)
    else
      self.parent_node = nil
    end
  end

  def destination_filename
    parent_node ? ::File.join(parent_node.filename, basename) : basename
  end

  def move
    return false if invalid?

    before_url = source.url.dup
    source.cur_node = nil
    source.filename = destination_filename
    source.basename = nil
    result = source.save
    if result && SS.config.cms.replace_urls_after_move
      job_class = Cms::Page::MoveJob.bind(site_id: cur_site, user_id: cur_user)
      job_class.perform_later(src: before_url, dst: source.url)
    else
      SS::Model.copy_errors(source, self)
    end
    result
  end

  private

  def fix_extname
    # nothing
  end

  def validate_basename
    if basename.blank?
      errors.add :basename, :blank
      return
    end
    if basename !~ /^[\w\-]+$/
      errors.add :basename, :invalid_filename
    end

    dst = destination_filename

    if dst !~ /^([\w\-]+\/)*[\w\-]+(#{::Regexp.escape(fix_extname || "")})?$/
      errors.add :basename, :invalid
    end

    if source.filename == dst
      errors.add :base, :same_filename
    end
    if Cms::Node.site(cur_site).where(filename: dst).first
      errors.add :basename, :taken
    end
    if Fs.exist?("#{cur_site.path}/#{dst}")
      errors.add :base, :exist_physical_file
    end

    if parent_node.present?
      errors.add :base, :subnode_of_itself if source.filename == parent_node.filename

      allowed = parent_node.allowed?(:read, cur_user, site: cur_site)
      errors.add :base, :not_have_parent_read_permission unless allowed
    end
  end
end
