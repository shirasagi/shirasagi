class Rss::PubSubHubbub::VerificationParam
  include ActiveModel::Model

  attr_accessor :cur_node
  attr_accessor :mode, :topic, :challenge, :lease_seconds

  validate :validate_mode
  validate :validate_topic
  validate :validate_challenge

  private
    def validate_mode
      errors.add :mode, :invalid unless %w(subscribe unsubscribe).include?(mode)
    end

    def validate_topic
      if topic.blank?
        errors.add :topic, :blank
        return
      end

      return if cur_node.blank?
      return if cur_node.topic_urls.blank?

      unless cur_node.topic_urls.include?(topic)
        errors.add :topic, :inclusion
      end
    end

    def validate_challenge
      errors.add :challenge, :blank if mode == 'subscribe' && challenge.blank?
    end
end
