module SS::FileFactory
  extend ActiveSupport::Concern

  included do
    attr_accessor :in_files
    permit_params :in_files, in_files: []
  end

  def save_files
    return false unless valid?

    in_files.each do |file|
      item = self.class.send(:new, attributes)
      item.cur_site = cur_site if respond_to?(:cur_site)
      item.cur_user = cur_user if respond_to?(:cur_user)
      item.cur_node = cur_node if respond_to?(:cur_node)
      item.in_file = file
      item.resizing = resizing
      next if item.save

      item.errors.full_messages.each { |m| errors.add :base, m }
      return false
    end
    true
  end
end
