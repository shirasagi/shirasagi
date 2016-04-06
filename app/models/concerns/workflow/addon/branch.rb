module Workflow::Addon
  module Branch
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      field :master_id, type: Integer

      belongs_to :master, foreign_key: "master_id", class_name: self.to_s
      has_many :branches, foreign_key: "master_id", class_name: self.to_s, dependent: :destroy

      permit_params :master_id

      before_validation :seq_clone_filename, if: ->{ new_clone? && (new_record? || basename.blank?) }
      after_save :merge_to_master

      define_method(:master?) { master.blank? }
      define_method(:branch?) { master.present? }
    end

    def new_clone?
      @new_clone == true
    end

    def cloned_name?
      prefix = I18n.t("workflow.cloned_name_prefix")
      name =~ /^\[#{Regexp.escape(prefix)}\]/
    end

    def new_clone(attributes = {})
      attributes = self.attributes.merge(attributes).select{ |k| self.fields.keys.include?(k) }

      item = self.class.new(attributes)
      item.id = nil
      item.state = "closed"
      item.cur_user = @cur_user
      item.cur_site = @cur_site
      item.cur_node = @cur_node
      if attributes["filename"].nil?
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

      item.instance_variable_set(:@new_clone, true)
      item
    end

    def clone_files
      ids = SS::Extensions::Words.new
      files.each do |f|
        attributes = Hash[f.attributes]
        attributes.select!{ |k| f.fields.keys.include?(k) }

        file = SS::File.new(attributes)
        file.id = nil
        file.in_file = f.uploaded_file
        file.user_id = @cur_user.id if @cur_user

        file.save validate: false
        ids << file.id.mongoize

        html = self.html
        next unless html.present?

        html.gsub!("=\"#{f.url}\"", "=\"#{file.url}\"")
        html.gsub!("=\"#{f.thumb_url}\"", "=\"#{file.thumb_url}\"")
        self.html = html
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
      self.allow_other_user_files if respond_to?(:allow_other_user_files)
      self.save
    end

    def merge_to_master
      return unless branch?
      return unless state == "public"

      master = self.master
      master.cur_user = @cur_user
      master.cur_site = @cur_site
      master.merge(self)
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
        if master.present?
          seq_clone_filename_with_master
        else
          seq_clone_filename_without_master
        end
      end

      def seq_clone_filename_with_master
        filename_backup = File.basename(master.filename)
        filename_backup = filename_backup.gsub(File.extname(master.filename), '')
        last_branch = master.branches.order(created_at: -1).first
        if last_branch.nil?
          number = '01'
        else
          last_branch.filename.gsub(File.extname(last_branch.filename), '') =~ /.*_(\d\d)/
          matched = $1
          if matched
            number = format("%02d", matched.to_i + 1)
          else
            number = '01'
          end
        end
        self.filename ||= ""
        self.filename = dirname ? "#{dirname}/#{filename_backup}_#{number}.html" : "#{filename_backup}_#{number}.html"
      end

      def seq_clone_filename_without_master
        self.filename ||= ""
        self.filename = dirname ? "#{dirname}/#{id}.html" : "#{id}.html"
      end
  end
end
