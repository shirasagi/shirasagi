module SS::FileFactory
  extend ActiveSupport::Concern

  included do
    attr_accessor :in_files, :saved_files
    permit_params :in_files, in_files: []
  end

  module ClassMethods
    def create_empty!(attributes, options = {})
      item = new(attributes)
      if item.respond_to?(:disable_thumb=)
        item.disable_thumb = true # サムネイル作成時にエラーになるので、無効にする
      end
      item.name = ::File.basename(item.filename) if item.name.blank? && item.filename.present?
      item.size = 0
      if options.fetch(:validate, true)
        item.save!
      else
        item.save(validate: false)
      end

      # `in_file` を指定していないので before_save でエラーが発生するが、
      # 空のファイルを作成するのが目的なので、そのエラーは無視して安全。
      item.errors.clear

      # フラグを元に戻す
      if item.respond_to?(:disable_thumb=)
        item.disable_thumb = nil
      end

      # ファイルが存在しない場合、空のファイルを作成する。
      path = item.path
      if !::File.exists?(path)
        dirname = ::File.dirname(path)
        ::FileUtils.mkdir_p(dirname) if !::Dir.exists?(dirname)
        ::FileUtils.touch(path)
      end

      if block_given?
        yield item
        item.sync_stats
      end

      item
    end
  end

  def save_files
    return false unless valid?

    self.saved_files = []

    in_files.each do |file|
      item = self.class.send(:new, attributes)
      item.cur_site = cur_site if respond_to?(:cur_site)
      item.cur_user = cur_user if respond_to?(:cur_user)
      item.cur_node = cur_node if respond_to?(:cur_node)
      item.cur_group = cur_group if respond_to?(:cur_group)
      item.in_file = file
      item.resizing = resizing
      item.unnormalize = unnormalize
      if item.save
        self.saved_files << item
        next
      end

      item.errors.full_messages.each { |m| errors.add :base, m }
      return false
    end
    true
  end

  def sync_stats
    self.set(size: ::File.size(self.path))
  end
end
