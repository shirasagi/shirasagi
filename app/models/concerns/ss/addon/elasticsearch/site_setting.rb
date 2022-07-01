module SS::Addon::Elasticsearch::SiteSetting
  extend ActiveSupport::Concern
  extend SS::Addon

  included do
    field :elasticsearch_hosts, type: SS::Extensions::Words
    field :elasticsearch_deny, type: SS::Extensions::Lines, default: '404.html'
    field :elasticsearch_indexes, type: SS::Extensions::Words
    field :elasticsearch_outside, type: String, default: 'disabled'
    embeds_ids :elasticsearch_sites, class_name: "Cms::Site"

    permit_params :elasticsearch_hosts, :elasticsearch_deny, :elasticsearch_indexes, :elasticsearch_outside
    permit_params elasticsearch_site_ids: []

    after_save :deny_elasticsearch_paths, if: ->{ @db_changes["elasticsearch_deny"] }
  end

  def menu_elasticsearch_visible?
    elasticsearch_enabled?
  end

  def elasticsearch_enabled?
    elasticsearch_hosts.present?
  end

  # 存在しない文書を削除すると、Elasticsearch の Transport 層から FATAL レベルのログが出力されてしまう。
  # この FATAL レベルのログは無視しても問題ないが、production.log が無駄な FATAL で埋め尽くされ、本当のエラーに気づきづらくしてしまう。
  # そこで FATAL レベルのログを INFO レベルへリダイレクトする。
  #
  # なお、FATAL レベルのログが Elasticsearch の Transport 層で出力された後、必ず例外が発生する。
  # その例外はシラサギで補足され、適切なレベルでログに出力される。
  class ESTransportLogger
    SEVERITY_REDIRECTION_MAP = {
      fatal: :info
    }.freeze

    class << self
      %i[debug info warn error fatal].each do |severity|
        define_method(severity) do |*args, &block|
          severity = SEVERITY_REDIRECTION_MAP.fetch(severity, severity)
          Rails.logger.send(severity, *args, &block)
        end

        define_method("#{severity}?") do
          severity = SEVERITY_REDIRECTION_MAP.fetch(severity, severity)
          Rails.logger.send("#{severity}?")
        end
      end
    end
  end

  def elasticsearch_client
    return unless elasticsearch_enabled?
    @elasticsearch_client ||= Elasticsearch::Client.new(hosts: elasticsearch_hosts, logger: ESTransportLogger)
  end

  def elasticsearch_outside_options
    %w(disabled enabled).map { |m| [ I18n.t("ss.options.state.#{m}"), m ] }.to_a
  end

  def elasticsearch_outside_enabled?
    elasticsearch_outside == 'enabled'
  end

  private

  def deny_elasticsearch_paths
    es_client = elasticsearch_client
    return unless es_client

    index_name = "s#{id}"
    index_type = Cms::Page.collection_name

    elasticsearch_deny.each do |path|
      path.slice!(0) if path.start_with?('/')
      begin
        es_client.delete(index: index_name, type: index_type, id: path)
      rescue Elasticsearch::Transport::Transport::Errors::NotFound => e
        Rails.logger.debug { "#{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}" }
      end
    end
  end
end
