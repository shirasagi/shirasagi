class Cms::Transaction::Unit::Command < Cms::Transaction::Unit::Base
  include Cms::Addon::Transaction::Command

  def type
    "command"
  end

  def execute_main
    if command.blank?
      task.log "command not registered"
      return
    end

    stdout, stderr, status = Open3.capture3(command)
    task.log [stdout, stderr, status.to_s].select(&:present?).join("\n")
  end
end
