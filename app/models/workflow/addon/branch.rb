module Workflow::Addon
  module Branch
    extend ActiveSupport::Concern
    extend SS::Addon

    set_order 20

    included do
      field :master_id, type: Integer
      belongs_to :master, foreign_key: "master_id", class_name: self.to_s
      has_many :branches, foreign_key: "master_id", class_name: self.to_s, dependent: :destroy

      define_method(:master?) { master.blank? }
      define_method(:branch?) { master.present? }

      permit_params :master_id

      after_save :merge_to_master
    end

    public
      def new_clone?
        @new_clone == true
      end

      def new_clone(attributes = {})
        attributes = self.attributes.merge(attributes).select{ |k| self.fields.keys.include?(k) }

        item = self.class.new(attributes)
        item.id = nil
        item.state = "closed"
        item.cur_user = @cur_user
        item.cur_site = @cur_site
        if attributes[:filename].nil?
          item.filename = item.dirname("copy-" + rand(0xffff_ffff_ffff_ffff).to_s(32))
        end
        item.instance_variable_set(:@new_clone, true)
        item
      end

      def clone_files
        ids = SS::Extensions::Array.new
        files.each do |f|
          attributes = Hash[f.attributes]
          attributes.select!{ |k| f.fields.keys.include?(k) }

          file = SS::File.new(attributes)
          file.id = nil
          file.in_file = f.uploaded_file
          file.user_id = @cur_user.id if @cur_user

          if file.save
            ids << file.id.mongoize

            html = self.html
            html.gsub!("=\"#{f.url}\"", "=\"#{file.url}\"")
            html.gsub!("=\"#{f.thumb_url}\"", "=\"#{file.thumb_url}\"")
            self.html = html
          end
        end
        self.file_ids = ids
      end

      def merge(branch)
        attributes = Hash[branch.attributes]
        attributes.delete("_id")
        attributes.delete("filename")
        attributes.select!{ |k| self.fields.keys.include?(k) }

        self.attributes = attributes
        self.master_id = nil
        self.allow_other_user_files
        self.save
      end

      def merge_to_master
        return unless branch?
        return if state == "closed"

        master = self.master
        master.cur_user = @cur_user
        master.cur_site = @cur_site
        master.merge(self)
      end
  end
end
