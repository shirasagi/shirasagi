module Workflow
  module_function

  def exceed_remind_limit?(duration, content, now: nil)
    now ||= Time.zone.now.change(usec: 0)
    now > content.updated + duration
  end
end
