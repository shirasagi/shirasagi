module Workflow::Addon
  module Branch
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      attr_accessor :in_branch

      define_model_callbacks :merge_branch

      belongs_to :master, foreign_key: "master_id", class_name: self.to_s
      has_many :branches, foreign_key: "master_id", class_name: self.to_s, dependent: :destroy

      permit_params :master_id

      validate :validate_master_lock, if: ->{ branch? }

      before_merge_branch :merge_file_histories rescue nil

      before_save :seq_clone_filename, if: ->{ new_clone? && basename.blank? }
      after_save :merge_to_master

      define_method(:master?) { master.blank? }
      define_method(:branch?) { master.present? }

      index({ master_id: 1 })
    end

    def new_clone?
      @new_clone == true
    end

    def cloned_name?
      prefix = I18n.t("workflow.cloned_name_prefix")
      name =~ /^\[#{::Regexp.escape(prefix)}\]/
    end

    module Utils
      module_function

      def clone_attributes(item, attributes_to_override = nil)
        attributes = Hash[item.attributes]
        attributes.stringify_keys!
        # "#attributes" では現在では廃止されている属性が取得される場合がある；それを除去する
        attributes.select! { |k, _v| item.fields.key?(k) }

        attr_names_to_clear = item.fields.select { |n, v| v.options.dig(:metadata, :on_copy) == :clear }.map { |n, v| n }
        # new を呼び出す前に _id を削除しておかないと `#branches` などの参照が変になる
        attr_names_to_clear << "_id"
        # 特定の日付フィールドはクリアしておく
        attr_names_to_clear << "updated"
        attr_names_to_clear << "created"

        attributes = attributes.except(*attr_names_to_clear)

        attributes["filename"] = "#{item.dirname}/" if attributes.key?("filename")
        attributes["state"] = "closed" if attributes.key?("state")

        if attributes_to_override
          attributes_to_override = attributes_to_override.stringify_keys
          attributes_to_override.select! { |k, _v| item.fields.key?(k) }

          attributes.merge!(attributes_to_override)
        end

        attributes
      end

      ATTR_NAMES_TO_DELETE_ON_MERGE = [
        # _id を念のため削除しておく
        "_id",
        # 特定の日付フィールドは上書きしないように削除しておく
        "updated", "created",
        # 他、上書きしないように削除
        "filename", "master_id"
      ].freeze

      def merge_attributes(master, branch)
        attributes = Hash[master.attributes]
        attributes.stringify_keys!
        # "#attributes" では現在では廃止されている属性が取得される場合がある；それを除去する
        attributes.select! { |k, _v| master.fields.key?(k) }

        attributes_to_override = Hash[branch.attributes]
        attributes_to_override.stringify_keys!

        master.fields.each do |field_name, field_info|
          if ATTR_NAMES_TO_DELETE_ON_MERGE.include?(field_name)
            attributes.delete(field_name)
            next
          end

          on_merge = field_info.options.dig(:metadata, :on_merge)
          case on_merge
          when :clear
            attributes[field_name] = field_info.default_val
          when :keep
            attributes.delete(field_name)
          else
            if attributes.key?(field_name)
              attributes[field_name] = attributes_to_override[field_name] || field_info.default_val
            elsif attributes_to_override.key?(field_name)
              attributes[field_name] = attributes_to_override[field_name]
            end
          end
        end

        attributes
      end
    end

    def new_clone(attributes_to_override = nil)
      attributes = Utils.clone_attributes(self, attributes_to_override)
      item = self.class.new(attributes)
      item.cur_user = @cur_user
      item.cur_site = @cur_site
      item.cur_node = @cur_node

      if item.is_a?(Cms::Addon::Form::Page)
        item.copy_column_values(self)
      end

      item.instance_variable_set(:@new_clone, true)
      item
    end

    def clone_files
      run_callbacks(:clone_files) do
        ids = {}
        files.each do |f|
          ids[f.id] = clone_file(f).id
        end
        self.file_ids = ids.values
        ids
      end
    end

    def clone_file(source_file)
      attributes = Hash[source_file.attributes]
      attributes.select!{ |k| source_file.fields.key?(k) }

      attributes["user_id"] = @cur_user.id if @cur_user
      attributes["_id"] = nil
      attributes["master_id"] = source_file.id
      file = SS::File.create_empty!(attributes, validate: false) do |new_file|
        ::FileUtils.copy(source_file.path, new_file.path)
        new_file.sanitizer_copy_file
      end

      if respond_to?(:html) && html.present?
        html = self.html
        html.gsub!("=\"#{source_file.url}\"", "=\"#{file.url}\"")
        html.gsub!("=\"#{source_file.thumb_url}\"", "=\"#{file.thumb_url}\"")
        self.html = html
      end

      if respond_to?(:body_parts) && body_parts.present?
        self.body_parts = body_parts.map do |html|
          html = html.to_s
          html = html.gsub("=\"#{source_file.url}\"", "=\"#{file.url}\"")
          html = html.gsub("=\"#{source_file.thumb_url}\"", "=\"#{file.thumb_url}\"")
          html
        end
      end

      file
    end

    def clone_thumb
      run_callbacks(:clone_thumb) do
        return if thumb.blank?
        self.thumb = clone_file(thumb)
        thumb
      end
    end

    # backwards compatibility
    def merge(branch)
      Rails.logger.warn(
        'DEPRECATION WARNING:' \
        ' merge is deprecated and will be removed in future version (use merge_branch instead).'
      )
      self.in_branch = branch
      self.merge_branch
    end

    def merge_branch
      return unless in_branch

      run_callbacks(:merge_branch) do
        self.reload

        attributes = Utils.merge_attributes(self, in_branch)
        self.attributes = attributes
        self.master_id = nil
        self.allow_other_user_files if respond_to?(:allow_other_user_files)
        clone_thumb
      end
      self.skip_history_trash = true if self.respond_to?(:skip_history_trash)
      self.save
    end

    def merge_file_histories
      return unless in_branch

      in_branch.attached_files.each do |file|
        master_file = file.master

        # update history files
        if master_file
          master_file.save_history_file
          file.history_file_ids = master_file.history_file_ids
          master_file.history_file_ids = []
        end

        # update owner item
        file.owner_item = self

        # update file's master
        file.master = nil
        file.save!

        master_file.save! if master_file
      end
    end

    def merge_to_master
      return unless branch?
      return unless state == "public"

      master = self.master
      master.cur_user = @cur_user
      master.cur_site = @cur_site
      master.in_branch = self
      if !master.merge_branch
        Rails.logger.error("merge_branch : master save failed #{master.errors.full_messages.join(",")}")
      end

      master.generate_file
    end

    private

    def serve_static_file?
      return false if branch?
      super
    end

    def validate_filename
      super unless new_clone?
    end

    def seq_clone_filename
      self.filename ||= ""
      self.filename = dirname ? "#{dirname}#{id}.html" : "#{id}.html"
    end

    def validate_master_lock
      return if !master.respond_to?("locked?")
      return if self.state != "public"

      if master.locked? && !master.lock_owned?(@cur_user)
        errors.add :base, :locked, user: (master.lock_owner.try(:long_name) || "no name")
      end
    end
  end
end
