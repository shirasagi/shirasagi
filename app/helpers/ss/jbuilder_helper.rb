module SS::JbuilderHelper
  def format_json_datetime(json, item)
    format = SS.config.env.json_datetime_format
    return if format.blank?
    item.class.fields.each do |k, v|
      next unless %w(Date DateTime Time TimeWithZone).index(v.type.to_s)
      json.set!(k, @item.send(k).strftime(format)) rescue next
    end
  end

  def decorate_with_relations(json, item)
    item.class.fields.each do |k, v|
      if file_field?(v)
        k = k.sub('_id', '')
        file = item.send(k) rescue next
        json.set!(k, jsonize_file(file)) rescue next
      end

      if files_field?(v)
        k = k.sub('_ids', '').pluralize
        files = item.send(k) rescue next
        h = {}
        files.each do |file|
          h[file.id] = jsonize_file(file) rescue next
        end
        next if h.blank?
        json.set!(k, h)
      end

      if nodes_field?(v)
        k = k.sub('_ids', '').pluralize
        nodes = item.send(k) rescue next
        h = {}
        nodes.each do |node|
          h[node.id] = jsonize_node(node) rescue next
        end
        next if h.blank?
        json.set!(k, h)
      end
    end
  end

  private
    def file_field?(field_def)
      metadata = field_def.metadata
      return false if metadata.blank?

      file_class?(metadata.try(:class_name))
    end

    def files_field?(field_def)
      metadata = field_def.metadata
      return false if metadata.blank?

      file_class?(metadata.try(:[], :elem_class))
    end

    def nodes_field?(field_def)
      metadata = field_def.metadata
      return false if metadata.blank?

      node_class?(metadata.try(:[], :elem_class))
    end

    def file_class?(class_name)
      return false if class_name.blank?

      cls = class_name.constantize rescue nil
      return false if cls.blank?

      cls.ancestors.include?(SS::Model::File)
    end

    def node_class?(class_name)
      return false if class_name.blank?

      cls = class_name.constantize rescue nil
      return false if cls.blank?

      cls.ancestors.include?(Cms::Model::Node)
    end

    def jsonize_file(file)
      { name: file.name, filename: file.filename, url: file.full_url,
        content_type: file.content_type, updated: file.updated }
    end

    def jsonize_node(node)
      { name: node.name, filename: node.filename, url: node.full_url,
        path: node.private_show_path, updated: node.updated }
    end
end
