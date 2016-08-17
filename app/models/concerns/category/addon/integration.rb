module Category::Addon
  module Integration
    extend SS::Addon
    extend ActiveSupport::Concern
    include ::Category::Addon::Model::Integration

    included do
      attr_accessor :in_partial_id
      permit_params :in_partial_id
    end

    def category_integrate
      partial = ::Category::Node::Base.site(@cur_site).find(in_partial_id) rescue nil
      if !partial
        self.errors.add :base, I18n.t("errors.messages.partial_node_not_found")
        return false
      end

      validate_category_integration(partial)
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

    def validate_category_integration(partial)
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

      # validate children basenames duplication
      basenames = []
      %w(pages nodes parts layouts).each do |name|
        send(name).where(depth: depth + 1).each do |item|
          basenames << item.basename
          validate_partial_editor_lock(item)
        end

        partial.send(name).where(depth: partial.depth + 1).each do |item|
          if basenames.include?(item.basename)
            error_opts = { name: item.name, filename: item.filename }
            self.errors.add :base, I18n.t("errors.messages.partial_children_basename_duplication", error_opts)
          end
          validate_partial_editor_lock(item)
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

    def validate_partial_editor_lock(partial)
      error_opts = { name: partial.name, filename: partial.filename }

      # validate editor lock
      if partial.respond_to?(:locked?) && partial.locked?
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
  end
end
