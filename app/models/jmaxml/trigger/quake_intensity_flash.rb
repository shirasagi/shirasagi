# 震度速報
class Jmaxml::Trigger::QuakeIntensityFlash < Jmaxml::Trigger::Base
  include Jmaxml::Trigger::QuakeBase

  self.control_title = '震度速報'
end
