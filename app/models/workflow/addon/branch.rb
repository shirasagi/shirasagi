module Workflow::Addon
  module Branch
    extend ActiveSupport::Concern
    extend SS::Addon

    set_order 20

    included do
      field :master_id, type: Integer
      belongs_to :master, foreign_key: "master_id", class_name: "Cms::Page"
      has_many :branches, foreign_key: "master_id", class_name: "Cms::Page", dependent: :delete

      permit_params :master_id

      after_save :merge_to_master
    end

    public
      def branch?
        master.present?
      end

      def merge(branch)
        attr = Hash[branch.attributes]
        attr.delete("_id")
        attr.delete("filename")
        attr.select!{ |k| self.fields.keys.include?(k) }

        self.attributes = attr
        self.master_id = nil
        self.clone_files
        self.save
      end

      def merge_to_master
        return unless branch?
        return if state == "closed"

        master = self.master
        master.instance_variable_set(:@cur_user, @cur_user)
        master.merge(self)
      end
  end
end
