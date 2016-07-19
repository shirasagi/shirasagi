require 'rss'

class Rss::ImportJob < Rss::ImportBase

  attr_reader :errors

  class << self
    def register_jobs(site, user = nil)
      Rss::Node::Page.site(site).and_public.each do |node|
        register_job(site, node, user)
      end
    end

    def register_job(site, node, user = nil)
      if node.try(:rss_refresh_method) == Rss::Node::Page::RSS_REFRESH_METHOD_AUTO
        bind(site_id: site.host, node_id: node.id, user_id: user.present? ? user.id : nil).perform_later
      else
        Rails.logger.info("node `#{node.filename}` is prohibited to update")
      end
    end
  end

  private
    def before_import(*args)
      super

      begin
        @items = Rss::Wrappers.parse(node.rss_url)
      rescue => e
        Rails.logger.info("Rss::Wrappers.parse failer (#{e.message}):\n  #{e.backtrace.join("\n  ")}")
        @items = nil
      end
    end

    def after_import
      super
    end
end
