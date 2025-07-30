class Chorg::Runner < Cms::ApplicationJob
  include Chorg::Context
  include Chorg::Loggable
  include Chorg::MongoidSupport
  include Chorg::PrimitiveRunner
  include Chorg::Runner::Base

  MAIN = 'main'.freeze
  TEST = 'test'.freeze

  def models_scope
    site_ids = @cur_site.chorg_sites.pluck(:id)
    if site_ids.present?
      { site_id: { "$in" => site_ids } }
    else
      { site_id: @cur_site.id }
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
    when MAIN
      Chorg::MainRunner
    when TEST
      Chorg::TestRunner
    else
      nil
    end
  end
end
