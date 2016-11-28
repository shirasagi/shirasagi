# 津波情報
class Jmaxml::Trigger::TsunamiInfo < Jmaxml::Trigger::Base
  include Jmaxml::Addon::Trigger::Tsunami

  self.control_title = '津波情報'
end
