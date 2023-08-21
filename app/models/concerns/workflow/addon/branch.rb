module Workflow::Addon
  module Branch
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      attr_accessor :in_branch

      define_model_callbacks :merge_branch

      belongs_to :master, class_name: self.to_s
      has_many :branches, foreign_key: "master_id", class_name: self.to_s, dependent: :destroy

      permit_params :master_id

      validate :validate_master_lock, if: ->{ branch? }

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

    def new_clone(attributes = {})
      attributes = self.attributes.merge(attributes).select { |k| self.fields.key?(k) }
      self.fields.select { |n, v| (v.options.dig(:metadata, :branch) == false) }.each do |n, v|
        attributes.delete(n)
      end
      # new を呼び出す前に _id を削除しておかないと `#branches` などの参照が変になる
      attributes.delete("_id")

      item = self.class.new(attributes)
      item.state = "closed"
      item.cur_user = @cur_user
      item.cur_site = @cur_site
      item.cur_node = @cur_node
      item.filename = "#{dirname}/"
      item.basename = ""

      item.workflow_user_id = nil
      item.workflow_state = nil
      item.workflow_comment = nil
      item.workflow_approvers = nil
      item.workflow_required_counts = nil

      if item.is_a?(Cms::Addon::EditLock)
        item.lock_owner_id = nil
        item.lock_until = nil
      end

      if item.is_a?(Workflow::Addon::Branch)
        item.master_id = nil
      end

      if item.is_a?(Cms::Addon::TwitterPoster)
        item.twitter_auto_post = "expired"
        item.twitter_edit_auto_post = "disabled"
      end

      if item.is_a?(Cms::Addon::LinePoster)
        item.line_auto_post = "expired"
        item.line_edit_auto_post = "disabled"
      end

      if item.is_a?(Cms::Addon::Form::Page)
        item.copy_column_values(self)
      end

      item.instance_variable_set(:@new_clone, true)
      item
    end

    def clone_files
      return if file_ids.blank?
      return if respond_to?(:branch?) && branch?

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
      file = SS::File.clone_file(source_file, cur_user: @cur_user, owner_item: SS::Model.container_of(self))
      update_html_with_clone_file(source_file, file)
      file
    end

    def update_html_with_clone_file(old_file, new_file)
      if respond_to?(:html) && html.present?
        html = self.html
        html.gsub!("=\"#{old_file.url}\"", "=\"#{new_file.url}\"")
        html.gsub!("=\"#{old_file.thumb_url}\"", "=\"#{new_file.thumb_url}\"")
        self.html = html
      end

      if respond_to?(:body_parts) && body_parts.present?
        self.body_parts = body_parts.map do |html|
          html = html.to_s
          html = html.gsub("=\"#{old_file.url}\"", "=\"#{new_file.url}\"")
          html = html.gsub("=\"#{old_file.thumb_url}\"", "=\"#{new_file.thumb_url}\"")
          html
        end
      end
    end

    def clone_thumb
      return if thumb_id.blank?
      if thumb.blank?
        self.thumb_id = nil
        return
      end
      return if respond_to?(:branch?) && branch?

      self.thumb = clone_file(thumb)
    end

    def merge_branch
      return unless in_branch

      run_callbacks(:merge_branch) do
        self.reload

        attributes = {}
        in_branch_attributes = Hash[in_branch.attributes]
        self.fields.each do |k, v|
          next if k == "_id"
          next if k == "filename"
          next if v.options.dig(:metadata, :branch) == false
          attributes[k] = in_branch_attributes[k]
        end

        self.attributes = attributes
        self.master_id = nil
        self.allow_other_user_files if respond_to?(:allow_other_user_files)
      end
      self.save
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
        errors.add :base, :locked, user: master.lock_owner.long_name
      end
    end
  end
end
