class Gws::Chorg::Runner < Gws::ApplicationJob
  include Chorg::Context
  include Chorg::Loggable
  include Chorg::MongoidSupport
  include Chorg::PrimitiveRunner
  include Chorg::Runner::Base

  self.ss_mode = :gws
  self.group_class = Gws::Group
  self.user_class = Gws::User
  self.revision_class = Gws::Chorg::Revision
  self.config_p = ->{ OpenStruct.new(SS.config.gws.chorg) }

  MAIN = 'main'.freeze
  TEST = 'test'.freeze

  def models_scope
    {}
  end

  def target_site(entity)
    site = entity.try(:site)
    if site && site.class.include?(SS::Model::Group)
      site
    else
      super
    end
  end

  def self.job_class(type)
    case type
    when MAIN then
      Gws::Chorg::MainRunner
    when TEST then
      Gws::Chorg::TestRunner
    else
      nil
    end
  end
end
