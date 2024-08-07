class History::Trash
  include History::Model::Data
  include SS::Reference::Site
  include Cms::SitePermission

  permit_params :basename, :parent, :children, :state

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
    if opts[:parent].present? && opts[:create_by_trash].present? && parent.present?
      parent_opts = opts.dup
      parent_opts.delete(:basename)
      parent.restore(parent_opts)
    end
    data = self.data.dup
    if model.include?(Cms::Content) && data[:depth].present? && data[:depth] > 1
      dir = ::File.dirname(data[:filename]).sub(/^\.$/, "")
      dir.sub!(opts[:src_filename], opts[:dst_filename]) if opts[:src_filename].present? && opts[:dst_filename].present?
      item_parent = Cms::Node.where(site_id: data[:site_id], filename: dir).first
      if opts[:create_by_trash].present? && item_parent.blank?
        errors.add :base, :not_found_parent_node
        return false
      end
    end
    if data.key?(:state)
      if opts[:state].present?
        data[:state] = opts[:state]
      elsif ref_class == 'Uploader::Node::File'
        data[:state] = 'public'
      else
        data[:state] = 'closed'
      end
    end
    data[:master_id] = nil if model.include?(Workflow::Addon::Branch)
    data = restore_data(data, opts)
    if opts[:file_restore]
      item = Cms::File.new(site_id: data[:site_id])
    else
      item = model.find_or_initialize_by(_id: data[:_id], site_id: data[:site_id])
    end
    item = item.becomes_with_route(data[:route]) if data[:route].present?
    item.cur_node = item_parent if item.respond_to?(:cur_node=)
    if opts[:file_restore]
      data = data.except(*%w(id _id model node_id owner_item_type owner_item_id))
    end
    data.each do |k, v|
      item[k] = v
    end
    item.apply_status('closed', workflow_reset: true) if model.include?(Workflow::Addon::Approver)
    if opts[:basename].present? && item.respond_to?(:filename=) && item.respond_to?(:basename=)
      item.filename = nil
      item.basename = opts[:basename]
    end
    if item.respond_to?(:in_file)
      path = "#{self.class.root}/#{item.path.sub(/.*\/(ss_files\/)/, '\\1')}"
      file = Fs::UploadedFile.create_from_file(path, content_type: item.content_type) if File.exist?(path)
      item.in_file = file
    end
    if opts[:create_by_trash]
      if item.errors.present?
        SS::Model.copy_errors(item, self)
        return false
      end

      unless item.save
        SS::Model.copy_errors(item, self)
        return false
      end

      if model.include?(Cms::Content)
        src = item.path.sub("#{Rails.root}/public", self.class.root)
        Fs.mkdir_p(File.dirname(item.path))
        Fs.mv(src, item.path) if Fs.exist?(src)
      elsif model.include?(SS::Model::File)
        src = "#{self.class.root}/#{item.path.sub(/.*\/(ss_files\/)/, '\\1')}"
        Fs.mkdir_p(File.dirname(item.path))
        Fs.mv(src, item.path) if Fs.exist?(src)
      end
      self.destroy
    end
    if opts[:file_restore]
      item.group_ids = opts[:cur_group].try(:id).then { |id| id ? [ id ] : [] }
      item.save
      id = self.data[:_id]
      path = "#{self.class.root}/ss_files/" + id.to_s.chars.join("/") + "/_/#{id}"
      src = path
      file = Fs::UploadedFile.create_from_file(path, content_type: self.data[:content_type])
      Fs.mkdir_p(File.dirname(item.path))
      Fs.mv(src, item.path) if Fs.exist?(src)
      item.in_file = file
      item.save
      self.destroy
    end
    item
  end

  def restore!(opts = {})
    opts[:create_by_trash] = true
    self.restore(opts)
  end

  def file_restore!(opts = {})
    opts[:file_restore] = true
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
        criteria = criteria.where(ref_coll: /cms_nodes|cms_pages|cms_parts|cms_layouts|ss_files/)
      elsif params[:ref_coll].present?
        criteria = criteria.where(ref_coll: params[:ref_coll])
      end
      criteria
    end

    def restore!(opts = {})
      criteria.each do |item|
        self.with_scope(self.unscoped) do
          item.restore!(opts)
        end
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
