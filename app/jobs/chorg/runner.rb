class Chorg::Runner < Cms::ApplicationJob
  include Chorg::Context
  include Chorg::Loggable
  include Chorg::MongoidSupport
  include Chorg::PrimitiveRunner
  include Chorg::Runner::Base

  MAIN = 'main'.freeze
  TEST = 'test'.freeze

  def models_scope
    site_ids = @item.target_sites.map(&:id)
    if site_ids.present?
      { "site_id" => { "$in" => site_ids } }
    else
      {}
    end
  end

  def target_site(entity)
    site = entity.try(:site)
    if site && site.class.include?(SS::Model::Site)
      site
    else
      super
    end
  end

  def self.job_class(type)
    case type
    when MAIN then
      Chorg::MainRunner
    when TEST then
      Chorg::TestRunner
    else
      nil
    end
  end
end
