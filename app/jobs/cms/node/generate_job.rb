class Cms::Node::GenerateJob < Cms::ApplicationJob
  include Job::Cms::GeneratorFilter

  after_perform :run_public_file_remover_job

  self.task_name = "cms:generate_nodes"
  self.controller = Cms::Agents::Tasks::NodesController
  self.action = :generate

  def generate_key
    arguments.dig(0, :generate_key)
  end

  def task_name
    generate_key.present? ? "#{self.class.task_name} key=#{generate_key}" : self.class.task_name
  end

  private

  def run_public_file_remover_job
    SS::PublicFileRemoverJob.bind(site_id: site).perform_later
  end
end
