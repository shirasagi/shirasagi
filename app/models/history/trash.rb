class History::Trash
  include SS::Document
  include SS::Reference::User
  include SS::Reference::Site
  include Cms::SitePermission

  store_in_repl_master
  index({ created: -1 })

  field :version, type: String, default: SS.version
  field :ref_coll, type: String
  field :ref_class, type: String
  field :data, type: Hash

  permit_params :parent, :children, :state

  validates :ref_coll, presence: true
  validates :data, presence: true

  after_destroy :remove_all

  def model
    ref_class.constantize
  end

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
    attributes = data.dup
    attributes[:state] = opts[:state] if opts[:state].present?
    attributes[:state] = 'public' if ref_class == 'Uploader::Node::File'
    attributes[:state] = 'closed' if ref_class == 'Urgency::Node::Layout'
    attributes[:master_id] = nil if model.include?(Workflow::Addon::Branch)
    model.relations.each do |k, relation|
      case relation.class.to_s
      when Mongoid::Association::Referenced::HasMany.to_s
        if relation.dependent.present? && opts[:create_by_trash].present?
          self.class.where(ref_class: relation.class_name, "data.#{relation.foreign_key}" => attributes['_id']).restore!(opts)
        end
      when Mongoid::Association::Embedded::EmbedsMany.to_s
        next if attributes[k].blank?
        attributes[k] = attributes[k].collect do |relation|
          if relation['_type'].present?
            relation = relation['_type'].constantize.new(relation)
          else
            relation = model.relations[k].class_name.constantize.new(relation)
          end
          relation.fields.each do |key, field|
            if field.type == SS::Extensions::ObjectIds
              klass = field.options[:metadata][:elem_class].constantize
              next unless klass.include?(SS::Model::File)
              relation[key].each_with_index do |file_id, i|
                relation[key][i] = restore_file(file_id, opts)
              end
            else
              klass = field.association.class_name.constantize rescue nil
              next if klass.blank?
              next unless klass.include?(SS::Model::File)
              relation[key] = restore_file(relation[key], opts)
            end
          end
          relation
        end
      end
    end
    model.fields.each do |k, field|
      next if attributes[k].blank?
      if field.type == SS::Extensions::ObjectIds
        klass = field.options[:metadata][:elem_class].constantize
        next unless klass.include?(SS::Model::File)
        attributes[k] = attributes[k].collect do |file_id|
          restore_file(file_id, opts)
        end
      else
        klass = field.association.class_name.constantize rescue nil
        next if klass.blank?
        next unless klass.include?(SS::Model::File)
        attributes[k] = restore_file(attributes[k], opts)
      end
    end
    item = model.find_or_initialize_by(_id: data[:_id], site_id: data[:site_id])
    item = item.becomes_with_route(data[:route]) if data[:route].present?
    if model.include?(Cms::Content) && data[:depth] > 1
      dir = ::File.dirname(data[:filename]).sub(/^\.$/, "")
      item_parent = Cms::Node.where(site_id: data[:site_id], filename: dir).first
      item.errors.add :base, :not_found_parent_node if item_parent.blank?
    end
    attributes.each do |k, v|
      item[k] = v
    end
    item.apply_status('closed', workflow_reset: true) if model.include?(Workflow::Addon::Approver)
    if item.respond_to?(:in_file)
      path = "#{Rails.root}/private/trash/#{item.path.sub(/.*\/(ss_files\/)/, '\\1')}"
      file = Fs::UploadedFile.create_from_file(path, content_type: item.content_type) if File.exist?(path)
      item.in_file = file
    end
    if opts[:create_by_trash]
      if item.errors.blank? && item.save
        if model.include?(Cms::Content)
          src = item.path.sub("#{Rails.root}/public", "#{Rails.root}/private/trash")
          Fs.mkdir_p(File.dirname(item.path))
          Fs.mv(src, item.path) if Fs.exists?(src)
        end
        self.destroy
      else
        errors.add :base, item.errors.full_messages
        return false
      end
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
    return unless model.include?(Cms::Content)
    item = restore
    Fs.rm_rf(item.path.sub("#{Rails.root}/public", "#{Rails.root}/private/trash"))
  end

  def restore_file(file_id, opts = {})
    file = SS::File.where(id: file_id).first
    return file.id if file.present?
    file = self.class.where(ref_coll: 'ss_files', 'data._id' => file_id).first
    if file.present?
      file = opts[:create_by_trash] ? file.restore! : file.restore
    end
    return if file.blank?
    return unless opts[:create_by_trash]
    path = "#{Rails.root}/private/trash/#{file.path.sub(/.*\/(ss_files\/)/, '\\1')}"
    return unless File.exist?(path)
    FileUtils.mkdir_p(File.dirname(file.path))
    FileUtils.cp(path, file.path)
    FileUtils.rm_rf(File.dirname(path))
    file._id
  end
end
