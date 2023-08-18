class Uploader::FilesJob < Cms::ApplicationJob
  include Job::SS::TaskFilter

  self.task_class = Cms::Task
  self.task_name = "uploader:files"

  def perform(args)
    args.each do |arg|
      arg.each do |action, values|
        perform_action(action, values)
      end
    end
  end

  def perform_action(action, values)
    case action
    when :mkdir
      values.each { |v| FileUtils.mkdir_p(v) }
    when :rm
      values.each { |v| FileUtils.rm_rf(v) }
    when :mv
      FileUtils.mv(values[0], values[1], force: true)
    when :text
      ::File.write(values[0], values[1])
      ::Uploader::File.auto_compile(values[0])
    end
  end
end
