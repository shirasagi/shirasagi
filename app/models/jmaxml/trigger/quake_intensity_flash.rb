# 震度速報
class Jmaxml::Trigger::QuakeIntensityFlash < Jmaxml::Trigger::Base
  include Jmaxml::Addon::Trigger::Quake

  self.control_title = '震度速報'
end
