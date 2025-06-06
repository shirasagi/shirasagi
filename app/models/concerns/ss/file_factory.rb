module SS::FileFactory
  extend ActiveSupport::Concern

  included do
    attr_accessor :in_files, :saved_files

    permit_params :in_files, in_files: []
  end

  module ClassMethods
    def create_empty!(attributes, options = {})
      item = new(attributes)
      if item.respond_to?(:in_disable_variant_processing=)
        item.in_disable_variant_processing = true # サムネイル作成時にエラーになるので、無効にする
      end
      item.name = ::File.basename(item.filename) if item.name.blank? && item.filename.present?
      item.size = 0
      item.model ||= self.name.underscore
      if options.fetch(:validate, true)
        item.save!
      else
        item.save(validate: false)
      end

      # `in_file` を指定していないので before_save でエラーが発生するが、
      # 空のファイルを作成するのが目的なので、そのエラーは無視して安全。
      item.errors.clear

      # フラグを元に戻す
      if item.respond_to?(:in_disable_variant_processing=)
        item.in_disable_variant_processing = nil
      end

      # ファイルが存在しない場合、空のファイルを作成する。
      path = item.path
      if !::File.exist?(path)
        dirname = ::File.dirname(path)
        ::FileUtils.mkdir_p(dirname) if !::Dir.exist?(dirname)
        ::FileUtils.touch(path)
      end

      if block_given?
        yield item
        item.sync_stats
      end

      if SS::SvgSanitizer.sanitize(item.path, content_type: item.content_type)
        item.sync_stats
      end

      item.update_variants if options.fetch(:variant_processing, true) && item.respond_to?(:update_variants)

      item
    end

    def create_from_zip_entry!(zip_entry, site: nil, user: nil, node: nil, **options)
      basename = options.delete(:basename) || begin
        name = ::SS::Zip.safe_zip_entry_name(zip_entry)
        ::File.basename(name)
      end

      attr = { model: options.delete(:model) || "ss/temp_file", name: basename, filename: basename }
      attr[:site_id] = site.id if site
      if user
        attr[:cur_user] = user
        attr[:user_id] = user.id
      end
      attr[:node_id] = node.id if node
      attr[:content_type] = options.delete(:content_type) || ::Fs.content_type(basename)

      create_empty!(attr.update(options)) do |ss_file|
        zip_entry.get_input_stream do |io|
          ::IO.copy_stream(io, ss_file.path)
        end
      end
    end
  end

  def save_files
    self.saved_files = []

    in_files.each do |file|
      item = self.class.send(:new, attributes)
      item.cur_site = cur_site if respond_to?(:cur_site)
      item.cur_user = cur_user if respond_to?(:cur_user)
      item.cur_node = cur_node if respond_to?(:cur_node)
      item.cur_group = cur_group if respond_to?(:cur_group)
      item.cur_member = cur_member if respond_to?(:cur_member)
      item.in_file = file
      item.resizing = resizing
      item.quality = quality
      item.image_resizes_disabled = image_resizes_disabled
      if item.save
        self.saved_files << item
        next
      end

      SS::Model.copy_errors(item, self)
      return false
    end
    true
  end

  def sync_stats
    self.set(size: ::File.size(self.path))
  end
end
