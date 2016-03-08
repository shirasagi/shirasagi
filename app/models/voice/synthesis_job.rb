require 'bson'
require 'open-uri'

class Voice::SynthesisJob
  include Job::Worker

  self.job_options = { 'pool' => 'voice_synthesis' }

  def call(id_or_url, force = false)
    voice_file = Voice::File.find(id_or_url) rescue nil
    voice_file ||= Voice::File.find_or_create_by_url(id_or_url)
    return unless voice_file

    begin
      Rails.logger.info("synthesize: #{voice_file.url}")
      voice_file.synthesize force
    rescue OpenURI::HTTPError, ::Timeout::Error
      # do not record http errors like 404, 500.
      voice_file.destroy
      raise
    end
  end

  def self.purge_pending_tasks
    criteria = Job::Task.where(pool: 'voice_synthesis')
    return if criteria.count < 20
    count = criteria.where(started: nil).lt(created: 5.minutes.ago).destroy
    Rails.logger.info("purged #{count} voice task(s)")
    count
  end
end
