require 'bson'
require 'open-uri'

class Voice::SynthesisJob
  include Job::Worker

  self.job_options = { 'pool' => 'voice_synthesis' }

  public
    def call(id_or_url, force = false)
      voice_file = Voice::VoiceFile.find(id_or_url) rescue nil
      voice_file ||= Voice::VoiceFile.find_or_create_by_url(id_or_url)
      return unless voice_file

      begin
        Rails.logger.info("synthesize: #{voice_file.url}")
        voice_file.synthesize force
      rescue OpenURI::HTTPError, TimeoutError
        # do not record http errors like 404, 500.
        voice_file.destroy
        raise
      end
    end
end
