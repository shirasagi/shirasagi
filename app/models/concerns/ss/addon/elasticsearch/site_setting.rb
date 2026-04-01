module SS::Addon::Elasticsearch::SiteSetting
  extend ActiveSupport::Concern
  extend SS::Addon

  included do
    field :elasticsearch_hosts, type: SS::Extensions::Words
    field :elasticsearch_deny, type: SS::Extensions::Lines, default: '404.html'
    field :elasticsearch_indexes, type: SS::Extensions::Words
    field :elasticsearch_outside, type: String, default: 'disabled'
    embeds_ids :elasticsearch_sites, class_name: "Cms::Site"

    field :elasticsearch_user, type: String
    field :elasticsearch_password, type: String
    field :elasticsearch_ssl_verify_mode, type: String
    attr_accessor :in_elasticsearch_password, :rm_elasticsearch_password

    permit_params :elasticsearch_hosts, :elasticsearch_deny, :elasticsearch_indexes, :elasticsearch_outside
    permit_params elasticsearch_site_ids: []
    permit_params :elasticsearch_user, :in_elasticsearch_password, :rm_elasticsearch_password, :elasticsearch_ssl_verify_mode

    before_validation :update_elasticsearch_password
    validates :elasticsearch_ssl_verify_mode, inclusion: { in: %w(none peer client_once fail_if_no_peer_cert), allow_blank: true }
    after_save :deny_elasticsearch_paths, if: ->{ elasticsearch_deny_changed? || elasticsearch_deny_previously_changed? }
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

    @elasticsearch_client ||= begin
      params = {
        hosts: elasticsearch_hosts, logger: ESTransportLogger
      }
      if elasticsearch_user.present? && elasticsearch_password.present?
        params[:user] = elasticsearch_user
        params[:password] = SS::Crypto.decrypt(elasticsearch_password)
      end
      if elasticsearch_ssl_verify_mode == "none"
        params[:transport_options] = { ssl: { verify: false } }
      end
      Elasticsearch::Client.new(params)
    rescue => e
      Rails.logger.warn { "#{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}" }
      nil
    end
  end

  def elasticsearch_outside_options
    %w(disabled enabled).map { |m| [ I18n.t("ss.options.state.#{m}"), m ] }.to_a
  end

  def elasticsearch_outside_enabled?
    elasticsearch_outside == 'enabled'
  end

  def elasticsearch_ssl_verify_mode_options
    %w(none peer).map do |v|
      [ v, v ]
    end
  end

  private

  def update_elasticsearch_password
    if rm_elasticsearch_password == '1'
      self.elasticsearch_password = nil
      return
    end

    return if in_elasticsearch_password.blank?
    self.elasticsearch_password = SS::Crypto.encrypt(in_elasticsearch_password)
  end

  def deny_elasticsearch_paths
    es_client = elasticsearch_client
    return unless es_client

    index_name = "s#{id}"
    index_type = Cms::Page.collection_name

    elasticsearch_deny.each do |path|
      path.slice!(0) if path.start_with?('/')
      begin
        es_client.delete(index: index_name, type: index_type, id: path)
      rescue Elastic::Transport::Transport::Errors::NotFound => e
        Rails.logger.debug { "#{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}" }
      end
    end
  end
end
