module Workflow::Addon
  module Branch
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      attr_accessor :in_branch

      define_model_callbacks :merge_branch

      field :master_id, type: Integer

      belongs_to :master, foreign_key: "master_id", class_name: self.to_s
      has_many :branches, foreign_key: "master_id", class_name: self.to_s, dependent: :destroy

      permit_params :master_id

      validate :validate_master_lock, if: ->{ branch? }

      before_save :seq_clone_filename, if: ->{ new_clone? && basename.blank? }
      after_save :merge_to_master

      define_method(:master?) { master.blank? }
      define_method(:branch?) { master.present? }
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

      item = self.class.new(attributes)
      item.id = nil
      item.state = "closed"
      item.cur_user = @cur_user
      item.cur_site = @cur_site
      item.cur_node = @cur_node
      if attributes[:filename].nil?
        item.filename = "#{dirname}/"
        item.basename = ""
      end

      item.workflow_user_id = nil
      item.workflow_state = nil
      item.workflow_comment = nil
      item.workflow_approvers = nil
      item.workflow_required_counts = nil

      if item.is_a?(Cms::Addon::EditLock)
        item.lock_owner_id = nil
        item.lock_until = nil
      end

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
      file = SS::File.create_empty!(attributes, validate: false) do |new_file|
        ::FileUtils.copy(source_file.path, new_file.path)
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
        ' merge is deprecated and will be removed in future version (user merge_branch instead).'
      )
      self.in_branch = branch
      self.merge_branch
    end

    def merge_branch
      return unless in_branch

      run_callbacks(:merge_branch) do
        self.reload

        attributes = {}
        in_branch_attributes = in_branch.attributes.to_h
        self.fields.each do |k, v|
          next if k == "_id"
          next if k == "filename"
          next if v.options.dig(:metadata, :branch) == false
          attributes[k] = in_branch_attributes[k]
        end

        self.attributes = attributes
        self.master_id = nil
        self.allow_other_user_files if respond_to?(:allow_other_user_files)
        clone_thumb
      end
      self.skip_history_trash = true if self.respond_to?(:skip_history_trash)
      self.save
    end

    def merge_to_master
      return unless branch?
      return unless state == "public"

      master = self.master
      master.cur_user = @cur_user
      master.cur_site = @cur_site
      master.in_branch = self
      master.merge_branch
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
