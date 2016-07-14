module Rss::Public::PubSubHubbubFilter
  extend ActiveSupport::Concern

  included do
    cattr_accessor :job_model
    model Rss::Page
    set_job_model Rss::ImportFromFileJob
    before_action :set_verification_param, only: [:confirmation]
    before_action :set_subscription_param, only: [:subscription]
  end

  module ClassMethods
    def set_job_model(model)
      self.job_model = model
    end
  end

  private
    def job_model
      self.class.job_model
    end

    def set_verification_param
      @item ||= begin
        p = params.permit('hub.mode', 'hub.topic', 'hub.challenge', 'hub.lease_seconds')
        p = Hash[p.to_a.map { |key, value| [key.sub('hub.', ''), value ] }]
        p[:cur_node] = @cur_node
        Rss::PubSubHubbub::VerificationParam.new(p)
      end
    end

    def set_subscription_param
      body = request.body.read
      if @cur_node.secret.present?
        # check digest
        actual = OpenSSL::HMAC.hexdigest('sha1', @cur_node.secret, body)
        actual = "sha1=#{actual}"
        expected = request.headers['X-Hub-Signature']
        if expected != actual
          Rails.logger.warn("HMAC signature of the payload is mismatched. Expected: #{expected}, Actual: #{actual}")
          render text: '', layout: false, content_type: 'text/plain'
          return
        end
      end

      @item = Rss::TempFile.create_from_post(@cur_site, body, request.content_type)
    end

  public
    def pages
      @model.site(@cur_site).and_public(@cur_date).where(@cur_node.condition_hash)
    end

    def index
      @items = pages.order_by(@cur_node.sort_hash).
        page(params[:page]).
        per(@cur_node.limit)

      render_with_pagination @items
    end

    def confirmation
      if @item.valid?
        render text: @item.challenge, layout: false, content_type: 'text/plain'
      else
        render text: '', layout: false, content_type: 'text/plain', status: :not_found
      end
    end

    def subscription
      job_model.bind(site_id: @cur_site, node_id: @cur_node, user_id: @cur_user).perform_later(@item.id)

      render text: '', layout: false, content_type: 'text/plain'
    rescue => e
      Rails.logger.error("#{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}")
      render text: '', layout: false, content_type: 'text/plain'
    end
end
