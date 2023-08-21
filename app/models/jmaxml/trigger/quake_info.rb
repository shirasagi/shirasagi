# 震源・震度に関する情報
class Jmaxml::Trigger::QuakeInfo < Jmaxml::Trigger::Base
  include Jmaxml::Addon::Trigger::Quake

  self.control_title = '震源・震度に関する情報'
end
