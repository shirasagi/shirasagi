module Multilingual::Addon
  module Page
    extend ActiveSupport::Concern
    extend SS::Addon
    include Multilingual::Addon::Content

    included do
      #cms
      foreign_field :html
      foreign_field :files, :file_ids
      foreign_field :file, :file_id
      foreign_field :body_parts

      #ads
      foreign_field :link_url

      #contact
      foreign_field :contact_state
      foreign_field :contact_charge
      foreign_field :contact_tel
      foreign_field :contact_fax
      foreign_field :contact_email
      foreign_field :contact_group, :contact_group_id

      #event
      foreign_field :schedule
      foreign_field :venue
      foreign_field :content
      foreign_field :cost
      foreign_field :related_url
      foreign_field :contact
      foreign_field :additional_info

      #faq
      foreign_field :question

      #facility
      foreign_field :image, :image_id

      #map
      foreign_field :map_points

      show_foreign_addon Gravatar::Addon::Gravatar
      show_foreign_addon Cms::Addon::Body
      show_foreign_addon Cms::Addon::BodyPart
      show_foreign_addon Cms::Addon::File
      show_foreign_addon Map::Addon::Page
      show_foreign_addon Cms::Addon::RelatedPage
      show_foreign_addon Contact::Addon::Page
      show_foreign_addon Cms::Addon::Release
      show_foreign_addon Cms::Addon::ReleasePlan
      show_foreign_addon Cms::Addon::GroupPermission
      show_foreign_addon Event::Addon::Body
      show_foreign_addon Cms::Addon::AdditionalInfo
      show_foreign_addon Faq::Addon::Question
      show_foreign_addon Workflow::Addon::Approver
      show_foreign_addon Workflow::Addon::Branch

      native_only_field :event_name, :event_dates

      #after_create :clone_foreigners
    end

    def content_class
      Cms::Page
    end

    def content_name
      "page"
    end

    def new_clone
      @cur_node = nil if foreigner?
      return super
    end

    #def clone_foreigners
    #  return if foreigner?
    #  return if master?
    #
    #  master.foreigners.each do |item|
    #    n = item.new_clone
    #    n.filename = "#{item.lang}/#{self.filename}"
    #    n.basename = nil
    #    n.master = item
    #    n.native = self
    #    n.save!
    #  end
    #end
  end
end
