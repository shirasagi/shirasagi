# 津波警報・注意報・予報
class Jmaxml::Trigger::TsunamiAlert < Jmaxml::Trigger::Base
  include Jmaxml::Addon::Trigger::Tsunami

  self.control_title = '津波警報・注意報・予報'
end
