class Gws::Chorg::Task
  include SS::Model::Task
  include Chorg::Addon::EntityLog

  belongs_to :group, class_name: 'Gws::Group'
  belongs_to :revision, class_name: 'Gws::Chorg::Revision'

  validates :group_id, presence: true

  scope :group, ->(group) { where(group_id: group.id) }
  scope :and_revision, ->(revision) { where(revision_id: revision.id) }

  def entity_log_url(entity_site, entity_model, entity_index)
    url_helper = Rails.application.routes.url_helpers
    type = (name =~ /main_task$/) ? "main" : "test"
    url_helper.show_entity_gws_chorg_entity_logs_path(
      site: revision.site_id, rid: revision.id, type: type,
      entity_site: entity_site,
      entity_model: entity_model,
      entity_index: entity_index
    )
  end

  class << self
    # override scope
    def site(group)
      group(group)
    end
  end
end
