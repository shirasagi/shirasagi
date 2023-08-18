module Opendata::DatasetCopy
  extend ActiveSupport::Concern

  included do
    after_create :clone_resources, if: ->{ clone? }
  end

  def cloned_name?
    prefix = I18n.t("workflow.cloned_name_prefix")
    name =~ /^\[#{::Regexp.escape(prefix)}\]/
  end

  def new_clone(attributes = {})
    attributes = self.attributes.merge(attributes.stringify_keys).select { |k| self.fields.key?(k) }
    attributes.merge!(
      {
        id: nil,
        uuid: nil,
        cur_user: @cur_user,
        cur_site: @cur_site,
        cur_node: @cur_node,
        state: "closed",
        created: Time.zone.now,
        updated: Time.zone.now,
        released: nil,
        related_page_ids: [],
        related_page_sort: nil,
        point: 0,
        downloaded: 0,
        filename: "#{dirname}/",
        basename: "",
        release_date: nil,
        close_date: nil,
        update_plan_mail_state: "disabled"
      }.stringify_keys
    )
    item = self.class.new(attributes)
    item.reset_harvest_attributes
    item.instance_variable_set(:@original, self)
    item
  end

  private

  def clone?
    @original.present?
  end

  def clone_resources
    clone_file_resources
    clone_url_resources
  end

  def clone_file_resources
    @original.resources.each do |r|
      attributes = Hash[r.attributes]
      attributes.select!{ |k| r.fields.key?(k) }
      attributes.merge!(
        {
          id: nil,
          uuid: nil,
          revision_id: nil,
          file_id: nil,
          in_file: (r.source_url.present? ? nil : r.file.uploaded_file),
          tsv_id: nil,
          in_tsv: r.tsv.try(:uploaded_file),
          created: Time.zone.now,
          updated: Time.zone.now
        }.stringify_keys
      )
      resource = resources.new(attributes)
      resource.reset_harvest_attributes
      resource.save
    end
  end

  def clone_url_resources
    @original.url_resources.each do |r|
      attributes = Hash[r.attributes]
      attributes.select!{ |k| r.fields.key?(k) }
      attributes.merge!(
        {
          id: nil,
          uuid: nil,
          file_id: nil,
          in_file: r.file.uploaded_file,
          created: Time.zone.now,
          updated: Time.zone.now
        }.stringify_keys
      )
      url_resource = url_resources.new(attributes)
      url_resource.save
    end
  end
end
