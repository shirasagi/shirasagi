module SS::Relation::Thumb
  extend ActiveSupport::Concern
  extend SS::Translation

  def thumb_size(size)
    add_thumb_size(:normal, size)
  end

  def add_thumb_size(name, size)
    self.thumbs_resizing[name] = size
  end

  module ClassMethods
    def has_many_thumbs
      has_many :thumbs, class_name: "SS::ThumbFile", dependent: :destroy

      attr_accessor :thumbs_resizing

      after_initialize :initialize_thumbs_resizing
      after_save :save_thumbs, if: -> { image? }

      define_method("initialize_thumbs_resizing") do
        return if thumbs_resizing

        self.thumbs_resizing = thumbs.map { |t| [ t.image_size_name, t.image_size ] }.to_h
        self.thumbs_resizing.symbolize_keys!
      end

      define_method("thumb") do |key = nil|
        if key.nil?
          normal = thumbs.where(image_size_name: :normal).first
          normal ? normal : thumbs.first
        elsif key.kind_of?(Array)
          thumbs.where(image_size: key).first
        else
          thumbs.where(image_size_name: key).first
        end
      end

      define_method("thumb_url") do
        thumb ? thumb.url : super()
      end

      define_method("destroy_thumbs") do
        self.thumbs_resizing = {}
        result = thumbs.destroy_all
        reload
        result
      end

      define_method("save_thumbs") do
        thumbs.destroy_all if in_file || resizing
        thumbs_was = thumbs.map { |t| [t.image_size, t] }.to_h
        self.thumbs_resizing = thumbs_resizing.invert.invert #delete duplicate values

        thumbs_resizing.each do |name, size|
          file = thumbs_was.delete(size)
          if file
            file.update_attributes(filename: filename, state: state) if state_changed? || filename_changed?
            file.set(image_size_name: name)
          else
            file = SS::ThumbFile.new
            file.in_file         = uploaded_file
            file.filename        = file.in_file.original_filename
            file.image_size      = size
            file.resizing        = size
            file.image_size_name = name
            file.site_id         = site_id if respond_to?(:site_id)
            file.state           = state
            file.user_id         = user_id
            file.original_id     = id
            file.save
          end
        end

        thumbs_was.values.each(&:destroy)
        reload
      end

      ## generate first thumb file
      define_method("generate_public_file") do |*args|
        super(*args)
        thumb.generate_public_file if thumb
      end

      define_method("remove_public_file") do |*args|
        super(*args)
        thumb.remove_public_file if thumb
      end
    end
  end
end
