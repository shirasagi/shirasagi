module SS::Relation::Thumb
  extend ActiveSupport::Concern
  extend SS::Translation

  module ClassMethods
    private
      def use_relation_thumbs
        has_many :thumbs, class_name: "SS::ThumbFile", dependent: :destroy

        attr_accessor :thumbs_resizing

        after_initialize :initialize_thumbs_resizing
        after_save :save_thumbs, if: -> { image? }
      end
  end

  public
    def thumb_size(size)
      add_thumb_size(:normal, size)
    end

    def add_thumb_size(name, size)
      self.thumbs_resizing[name] = size
    end

    def thumb(key = nil)
      if key.nil?
        normal = thumbs.where(image_size_name: :normal).first
        normal ? normal : thumbs.first
      elsif key.kind_of?(Array)
        thumbs.where(image_size: key).first
      else
        thumbs.where(image_size_name: key).first
      end
    end

    def thumb_url
      thumb ? thumb.url : super
    end

    ## generate first thumb file
    def generate_public_file(*args)
      super
      thumb.generate_public_file if thumb
    end

    def remove_public_file(*args)
      super
      thumb.remove_public_file if thumb
    end

    def destroy_thumbs
      self.thumbs_resizing = {}
      result = thumbs.destroy_all
      reload
      result
    end

  private
    def initialize_thumbs_resizing
      return if thumbs_resizing

      self.thumbs_resizing = thumbs.map { |t| [ t.image_size_name, t.image_size ] }.to_h
      self.thumbs_resizing.symbolize_keys!
    end

    def save_thumbs
      thumbs.destroy_all if in_file || resizing
      thumbs_was = thumbs.map { |t| [t.image_size, t] }.to_h
      self.thumbs_resizing = thumbs_resizing.invert.invert #delete duplicate values

      thumbs_resizing.each do |name, size|
        file = thumbs_was.delete(size)
        if file
          file.update_attributes(filename: filename, state: state) if state_changed? || filename_changed?
          file.set(image_size_name: name) if name != file.image_size_name
        else
          file = SS::ThumbFile.new
          file.in_file         = uploaded_file
          file.resizing        = size
          file.original_id     = id
          file.state           = state
          file.filename        = file.in_file.original_filename
          file.image_size      = size
          file.image_size_name = name
          file.user_id         = user_id
          file.site_id         = site_id if respond_to?(:site_id)
          file.save
        end
      end

      thumbs_was.values.each(&:destroy)
      reload
    end
end
