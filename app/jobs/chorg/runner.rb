class Chorg::Runner < Cms::ApplicationJob
  include Chorg::Context
  include Chorg::Loggable
  include Chorg::MongoidSupport
  include Chorg::PrimitiveRunner
  include Chorg::Runner::Base

  MAIN = 'main'.freeze
  TEST = 'test'.freeze

  def models_scope
    { site_id: @cur_site.id }
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
