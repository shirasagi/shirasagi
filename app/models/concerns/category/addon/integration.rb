module Category::Addon
  module Integration
    extend SS::Addon
    extend ActiveSupport::Concern

    included do
      attr_accessor :in_partial_id
      permit_params :in_partial_id
    end

    def integrate
      partial = ::Category::Node::Base.site(@cur_site).find(in_partial_id) rescue nil
      if !partial
        self.errors.add :base, I18n.t("errors.messages.partial_node_not_found")
        return false
      end

      validate_integration(partial)
      if errors.empty?
        rename_partial_children(partial)
        integrate_embeds_ids(partial, self, Cms::Node)
        integrate_embeds_ids(partial, self, Cms::Page)
        partial.destroy
        true
      else
        false
      end
    end

    def validate_integration(partial)
      error_opts = { name: partial.name, filename: partial.filename }

      # validate allowed partial node
      if !partial.allowed?(:edit, @cur_user, site: @cur_site)
        self.errors.add :base, I18n.t("errors.messages.partial_auth_error", error_opts)
        return
      end

      # partial is master's ancestor node
      if filename == partial.filename || filename =~ /^#{partial.filename}\//
        self.errors.add :base, I18n.t("errors.messages.partial_ancestor_error", error_opts)
        return
      end

      # validate child basenames duplication
      basenames = []
      %w(pages nodes parts layouts).each do |name|
        send(name).where(depth: depth + 1).each do |item|
          basenames << item.basename
          validate_editor_lock(item)
        end

        partial.send(name).where(depth: partial.depth + 1).each do |item|
          if basenames.include?(item.basename)
            error_opts = { name: item.name, filename: item.filename }
            self.errors.add :base, I18n.t("errors.messages.partial_children_basename_duplication", error_opts)
          end
          validate_editor_lock(item)
        end
      end

      # validate static files duplication
      src_path = ::File.join(@cur_site.path, partial.filename)
      dst_path = ::File.join(@cur_site.path, filename)
      files= Fs.glob("#{dst_path}/**/{*,.*}").map { |item| item.sub(/#{dst_path}\//, "") }
      Fs.glob("#{src_path}/**/{*,.*}").each do |item|
        file = item.sub(/^#{src_path}\//, "")

        if files.include?(file)
          error_opts = { file: file }
          self.errors.add :base, I18n.t("errors.messages.partial_children_static_file_duplication", error_opts)
        end
      end
    end

    def validate_editor_lock(item)
      # validate editor lock
      if item.respond_to?(:locked?) && item.locked?
        self.errors.add :base, I18n.t("errors.messages.partial_children_static_file_duplication", error_opts)
      end
    end

    def rename_partial_children(partial)
      src_filename = partial.filename
      dst_filename = filename

      src_path = ::File.join(@cur_site.path, src_filename)
      dst_path = ::File.join(@cur_site.path, dst_filename)

      # move static files
      Fs.mkdir_p dst_path unless Fs.exists?(dst_path)
      Fs.glob("#{src_path}/**/{*,.*}").each do |src|
        dst = src.sub(/^#{src_path}\//, "#{dst_path}\/")
        Fs.mv src, dst if Fs.exists?(src)
      end

      # rename filenames
      %w(nodes pages parts layouts).each do |name|
        send(name).where(filename: /^#{src_filename}\//).each do |item|
          dst = item.filename.sub(/^#{src_filename}\//, "#{dst_filename}\/")
          item.set(
            filename: dst,
            depth: dst.scan("/").size + 1
          )
        end
      end
    end

    def integrate_embeds_ids(embedded, insert, content_model)
      item_ids = content_model.site(@cur_site).pluck(:id)
      item_ids.each do |item_id|
        item = content_model.site(@cur_site).find(item_id).becomes_with_route rescue nil
        next false unless item

        embeds_fields = item.fields.select do |n, v|
          next false unless n =~ /_ids$/
          next false unless v.type == SS::Extensions::ObjectIds

          begin
            elem_class = v.metadata[:elem_class]
            elem_class.constantize.include?(Cms::Model::Node)
          rescue
            false
          end
        end

        embeds_fields.keys.each do |k|
          ids = item.send(k)
          next unless ids.include?(embedded.id)
          item.add_to_set(k => insert.id)
        end
      end
    end
  end
end
