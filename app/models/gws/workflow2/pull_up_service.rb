class Gws::Workflow2::PullUpService < Gws::Workflow2::ApproveService
  def initialize(*args)
    super
    self.type = :pull_up
  end
end
