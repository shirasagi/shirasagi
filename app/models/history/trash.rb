class History::Trash
  include History::Model::Data
  include SS::Reference::Site
  include Cms::SitePermission

  permit_params :parent, :children, :state

  after_destroy :remove_all

  def parent
    path = File.dirname(data[:filename])
    self.class.where('data.filename' => path, 'data.site_id' => data[:site_id]).first
  end

  def children
    self.class.where('data.filename' => /\A#{::Regexp.escape(data[:filename] + '/')}/, 'data.site_id' => data[:site_id])
  end

  def target_options
    %w(unrestore restore).map { |v| [I18n.t("history.options.target.#{v}"), v] }
  end

  def state_options
    %w(closed public).map { |v| [I18n.t("ss.options.state.#{v}"), v] }
  end

  def restore(opts = {})
    parent.restore(opts) if opts[:parent].present? && opts[:create_by_trash].present? && parent.present?
    data = self.data.dup
    data[:state] = opts[:state] if opts[:state].present?
    data[:state] = 'public' if ref_class == 'Uploader::Node::File'
    data[:state] = 'closed' if ref_class == 'Urgency::Node::Layout'
    data[:master_id] = nil if model.include?(Workflow::Addon::Branch)
    data = restore_data(data, opts)
    item = model.find_or_initialize_by(_id: data[:_id], site_id: data[:site_id])
    item = item.becomes_with_route(data[:route]) if data[:route].present?
    if model.include?(Cms::Content) && data[:depth].present? && data[:depth] > 1
      dir = ::File.dirname(data[:filename]).sub(/^\.$/, "")
      item_parent = Cms::Node.where(site_id: data[:site_id], filename: dir).first
      item.errors.add :base, :not_found_parent_node if item_parent.blank?
    end
    data.each do |k, v|
      item[k] = v
    end
    item.apply_status('closed', workflow_reset: true) if model.include?(Workflow::Addon::Approver)
    if item.respond_to?(:in_file)
      path = "#{self.class.root}/#{item.path.sub(/.*\/(ss_files\/)/, '\\1')}"
      file = Fs::UploadedFile.create_from_file(path, content_type: item.content_type) if File.exist?(path)
      item.in_file = file
    end
    if opts[:create_by_trash]
      if item.errors.present?
        errors.add :base, item.errors.full_messages
        return false
      end

      unless item.save
        errors.add :base, item.errors.full_messages
        return false
      end

      if model.include?(Cms::Content)
        src = item.path.sub("#{Rails.root}/public", self.class.root)
        Fs.mkdir_p(File.dirname(item.path))
        Fs.mv(src, item.path) if Fs.exists?(src)
      elsif model.include?(SS::Model::File)
        src = "#{self.class.root}/#{item.path.sub(/.*\/(ss_files\/)/, '\\1')}"
        Fs.mkdir_p(File.dirname(item.path))
        Fs.mv(src, item.path) if Fs.exists?(src)
      end
      self.destroy
    end
    item
  end

  def restore!(opts = {})
    opts[:create_by_trash] = true
    self.restore(opts)
  end

  class << self
    def search(params = {})
      criteria = self.all
      return criteria if params.blank?

      if params[:name].present?
        criteria = criteria.search_text params[:name]
      end
      if params[:keyword].present?
        criteria = criteria.keyword_in params[:keyword], 'data.name', 'data.filename', 'data.html'
      end
      if params[:ref_coll] == 'all'
        criteria = criteria.where(ref_coll: /cms_nodes|cms_pages|cms_parts|cms_layouts/)
      elsif params[:ref_coll].present?
        criteria = criteria.where(ref_coll: params[:ref_coll])
      end
      criteria
    end

    def restore!(opts = {})
      criteria.each do |item|
        item.restore!(opts)
      end
    end
  end

  private

  def remove_all
    item = restore
    return if item.blank?

    if item.class.include?(::Cms::Content)
      path = item.path.sub("#{Rails.root}/public", self.class.root) rescue nil
    elsif ref_coll == 'ss_files'
      path = File.join(self.class.root, item.path.sub(/.*\/(ss_files\/)/, '\\1')) rescue nil
    end
    Fs.rm_rf(path) if path.present? && !path.start_with?("#{Rails.root}/public")
  end
end
