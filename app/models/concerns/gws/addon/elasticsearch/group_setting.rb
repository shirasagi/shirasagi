module Gws::Addon::Elasticsearch::GroupSetting
  extend ActiveSupport::Concern
  extend SS::Addon

  set_addon_type :organization

  included do
    field :elasticsearch_hosts, type: SS::Extensions::Words
    field :elasticsearch_user, type: String
    field :elasticsearch_password, type: String
    field :elasticsearch_ssl_verify_mode, type: String

    attr_accessor :in_elasticsearch_password, :rm_elasticsearch_password

    permit_params :elasticsearch_hosts, :elasticsearch_user, :in_elasticsearch_password, :rm_elasticsearch_password
    permit_params :elasticsearch_ssl_verify_mode

    before_validation :update_elasticsearch_password
    validates :elasticsearch_hosts, presence: true, if: ->{ menu_elasticsearch_visible? }
    validates :elasticsearch_ssl_verify_mode, inclusion: { in: %w(none peer client_once fail_if_no_peer_cert), allow_blank: true }
  end

  def elasticsearch_enabled?
    Rails.logger.warn('[DEPRECATION] `elasticsearch_enabled?` is deprecated.  Please use `menu_elasticsearch_visible?` instead.')
    menu_elasticsearch_visible?
  end

  def elasticsearch_client
    return unless menu_elasticsearch_visible?
    @elasticsearch_client ||= Elasticsearch::Client.new(hosts: elasticsearch_hosts, logger: Rails.logger)
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
    self.elasticsearch_password = SS::Crypto.crypt(in_elasticsearch_password)
  end
end
