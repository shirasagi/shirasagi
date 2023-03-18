module SS::JbuilderHelper
  def format_json_datetime(json, item)
    format = SS.config.env.json_datetime_format
    return if format.blank?
    item.class.fields.each do |k, v|
      next unless %w(Date DateTime Time TimeWithZone).index(v.type.to_s)
      json.set!(k, @item.send(k).strftime(format)) rescue next
    end
  end

  module Utils
    module_function

    def file_field?(field_def)
      metadata = field_def.options[:metadata]
      return false if metadata.blank?

      include_class?(metadata.try(:class_name), SS::Model::File)
    end

    def user_field?(field_def)
      association = field_def.try(:association)
      return false if association.blank?

      association.relation_class.ancestors.include?(SS::Model::User)
    end

    def files_field?(field_def)
      metadata = field_def.options[:metadata]
      return false if metadata.blank?

      include_class?(metadata.try(:[], :elem_class), SS::Model::File)
    end

    def nodes_field?(field_def)
      metadata = field_def.options[:metadata]
      return false if metadata.blank?

      include_class?(metadata.try(:[], :elem_class), Cms::Model::Node)
    end

    def users_field?(field_def)
      metadata = field_def.options[:metadata]
      return false if metadata.blank?

      include_class?(metadata.try(:[], :elem_class), SS::Model::User)
    end

    def groups_field?(field_def)
      metadata = field_def.options[:metadata]
      return false if metadata.blank?

      include_class?(metadata.try(:[], :elem_class), SS::Model::Group)
    end

    def include_class?(class_name, model)
      return false if class_name.blank?

      cls = class_name.constantize rescue nil
      return false if cls.blank?

      cls.ancestors.include?(model)
    end

    def jsonize_file(context, file)
      { name: file.name, filename: file.filename, url: file_full_url(context, file),
        content_type: file.content_type, updated: file.updated }
    end

    def file_full_url(context, file)
      if context.ss_mode == :gws
        request = context.request
        scheme = context.cur_site.try(:canonical_scheme).presence || request.try(:scheme)
        scheme ||= SS.config.gws.canonical_scheme.presence || "http"
        host = context.cur_site.try(:canonical_domain).presence || request.try(:host_with_port)
        host ||= SS.config.gws.canonical_domain
        "#{scheme}://#{host}/fs/" + SS::FilenameUtils.dirname_with_id(file.id) + "/_/#{file.filename}"
      else
        file.full_url
      end
    end

    def jsonize_node(node)
      { name: node.name, filename: node.filename, url: node.full_url,
        path: node.private_show_path, updated: node.updated }
    end

    def jsonize_user(user)
      { name: user.name, uid: user.uid, email: user.email }
    end

    def jsonize_group(group)
      { name: group.name }
    end

    def jsonize_file_field(context, key, field_def)
      return unless Utils.file_field?(field_def)

      key = key.sub('_id', '')
      file = context.item.send(key)
      context.json.set!(key, Utils.jsonize_file(context, file))
    end

    def jsonize_files_field(context, key, field_def)
      return unless Utils.files_field?(field_def)

      key = key.sub('_ids', '').pluralize
      files = context.item.send(key)
      h = {}
      files.each do |file|
        h[file.id] = Utils.jsonize_file(context, file)
      end
      return if h.blank?
      context.json.set!(key, h)
    end

    def jsonize_nodes_field(context, key, field_def)
      return unless Utils.nodes_field?(field_def)

      key = key.sub('_ids', '').pluralize
      nodes = context.item.send(key)
      h = {}
      nodes.each do |node|
        h[node.id] = Utils.jsonize_node(node)
      end
      return if h.blank?
      context.json.set!(key, h)
    end

    def jsonize_user_field(context, key, field_def)
      return unless Utils.user_field?(field_def)

      key = key.sub('_id', '')
      user = context.item.send(key)
      return unless user

      context.json.set!(key, Utils.jsonize_user(user))
    end

    def jsonize_users_field(context, key, field_def)
      return unless Utils.users_field?(field_def)

      key = key.sub('_ids', '').pluralize
      users = context.item.send(key)
      h = {}
      users.each do |user|
        h[user.id] = Utils.jsonize_user(user)
      end
      return if h.blank?
      context.json.set!(key, h)
    end

    def jsonize_groups_field(context, key, field_def)
      return unless Utils.groups_field?(field_def)

      key = key.sub('_ids', '').pluralize
      groups = context.item.send(key)
      h = {}
      groups.each do |group|
        h[group.id] = Utils.jsonize_group(group)
      end
      return if h.blank?
      context.json.set!(key, h)
    end

    JSONIZE_HANDLERS = %i[
      jsonize_file_field jsonize_files_field jsonize_nodes_field jsonize_user_field jsonize_users_field jsonize_groups_field
    ].freeze

    def jsonize_relations(context)
      context.item.class.fields.each do |k, v|
        JSONIZE_HANDLERS.each do |handler|
          Utils.send(handler, context, k, v) rescue nil
        end
      end
    end

    class Context
      include ActiveModel::Model

      attr_accessor :request, :ss_mode, :cur_site, :json, :item
    end
  end

  def decorate_with_relations(json, item)
    context = Utils::Context.new(request: request, ss_mode: @ss_mode, cur_site: @cur_site, json: json, item: item)
    Utils.jsonize_relations(context)
  end

  def jsonize_user(user)
    Utils.jsonize_user(user)
  end
end
