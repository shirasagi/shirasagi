class Cms::CheckLinks::IgnoreUrlMatcher
  include ActiveModel::Model

  cattr_accessor :systems, instance_accessor: false
  attr_accessor :cur_site

  Matcher = Data.define(:name, :match_proc) do
    def match?(*args, **kwargs)
      match_proc.call(*args, **kwargs)
    end

    def self.match_path?(lhs, rhs)
      case lhs
      when NilClass, ""
        # 右辺は何でもよい
        true
      else
        lhs == rhs
      end
    end

    def self.exact(name:, template:, template_hash:)
      match_proc = proc do |cur_site, full_url|
        full_url_hash = full_url.to_hash

        # host だけ特別。未指定の場合、自ホスト内のパスが指定されていると見なす
        if template_hash[:host]
          next false if template_hash[:host] != full_url_hash[:host]
        else
          next false unless cur_site.domains.include?(full_url_hash[:host])
        end

        # scheme と port は設定されていれば設定された通りにマッチする
        next false if template_hash[:scheme] && template_hash[:scheme] != full_url_hash[:scheme]
        next false if template_hash[:port] && template_hash[:port] != full_url_hash[:port]

        next false unless match_path?(template_hash[:path], full_url_hash[:path])

        # query と fragment は設定されていれば設定された通りにマッチする
        next false if template_hash[:query] && template_hash[:query] != full_url_hash[:query]
        next false if template_hash[:fragment] && template_hash[:fragment] != full_url_hash[:fragment]

        true
      end

      new(name: name, match_proc: match_proc)
    end

    def self.host_start_with(name:, template:, template_hash:)
      match_proc = proc do |_cur_site, full_url|
        full_url_hash = full_url.to_hash

        # request_uri は未指定のため origin（特に authority）が start_with かどうかをチェック
        next false unless full_url_hash[:host].start_with?(template_hash[:host])

        %i[scheme port].all? do |key|
          next true if template_hash[key].nil?
          template_hash[key] == full_url_hash[key]
        end
      end

      new(name: name, match_proc: match_proc)
    end

    def self.request_start_with(name:, template:, template_hash:)
      match_proc = proc do |cur_site, full_url|
        full_url_hash = full_url.to_hash
        next false unless match_origin?(cur_site, template_hash, full_url_hash)

        full_url.request_uri.start_with?(template.request_uri)
      end

      new(name: name, match_proc: match_proc)
    end

    def self.host_end_with(name:, template:, template_hash:)
      match_proc = proc do |_cur_site, full_url|
        full_url_hash = full_url.to_hash

        # request_uri は未指定のため origin（特に authority）が end_with かどうかをチェック
        next false unless full_url_hash[:host].end_with?(template_hash[:host])

        %i[scheme port].all? do |key|
          next true if template_hash[key].nil?
          template_hash[key] == full_url_hash[key]
        end
      end

      new(name: name, match_proc: match_proc)
    end

    def self.request_end_with(name:, template:, template_hash:)
      match_proc = proc do |cur_site, full_url|
        full_url_hash = full_url.to_hash
        next false unless match_origin?(cur_site, template_hash, full_url_hash)

        full_url.request_uri.end_with?(template.request_uri)
      end

      new(name: name, match_proc: match_proc)
    end

    def self.host_include(name:, template:, template_hash:)
      match_proc = proc do |_cur_site, full_url|
        full_url_hash = full_url.to_hash

        # request_uri は未指定のため origin（特に authority）が include かどうかをチェック
        next false unless full_url_hash[:host].include?(template_hash[:host])

        %i[scheme port].all? do |key|
          next true if template_hash[key].nil?
          template_hash[key] == full_url_hash[key]
        end
      end

      new(name: name, match_proc: match_proc)
    end

    def self.request_include(name:, template:, template_hash:)
      match_proc = proc do |cur_site, full_url|
        full_url_hash = full_url.to_hash
        next false unless match_origin?(cur_site, template_hash, full_url_hash)

        full_url.request_uri.include?(template.request_uri)
      end

      new(name: name, match_proc: match_proc)
    end

    def self.match_origin?(cur_site, template_hash, full_url_hash)
      # host だけ特別。未指定の場合、自ホスト内のパスが指定されていると見なす
      if template_hash[:host]
        return false if template_hash[:host] != full_url_hash[:host]
      else
        return false unless cur_site.domains.include?(full_url_hash[:host])
      end

      # host 以外は設定されていれば設定された通りにマッチする
      %i[scheme port].all? do |key|
        next true if template_hash[key].nil?
        template_hash[key] == full_url_hash[key]
      end
    end
  end

  class << self
    def match_scheme?(_cur_site, full_url)
      %w(http https).none? { full_url.scheme.casecmp(_1) == 0 } # other scheme
    end

    def match_asset?(_cur_site, full_url)
      full_url.path.match?(/\.(css|js|json)$/i)
    end

    def match_pagination?(_cur_site, full_url)
      full_url.path.match?(/\.p\d+\.html$/i)
    end

    # def match_event_calendar?(_cur_site, full_url)
    #   full_url.path.match?(/\/2\d{7}\.html$/i) # calendar
    # end

    def match_sns_share?(_cur_site, full_url)
      str_url = full_url.to_s
      return true if str_url.match?(/\/https?(:|%3a)/i) # b.hatena
      return true if str_url.match?(/\/\/twitter\.com/i) # twitter.com
      false
    end
  end

  self.systems = []
  self.systems << Matcher.new(name: :scheme, match_proc: self.method(:match_scheme?))
  self.systems << Matcher.new(name: :asset, match_proc: self.method(:match_asset?))
  self.systems << Matcher.new(name: :pagination, match_proc: self.method(:match_pagination?))
  # self.systems << Matcher.new(name: :event_calendar, match_proc: self.method(:match_event_calendar?))
  self.systems << Matcher.new(name: :sns_share, match_proc: self.method(:match_sns_share?))

  def match?(full_url)
    return true if self.class.systems.any? { _1.match?(cur_site, full_url) }
    return true if ignore_urls.any? { _1.match?(cur_site, full_url) }
    false
  end

  private

  def ignore_urls
    @ignore_urls ||= Cms::CheckLinks::IgnoreUrl.site(cur_site).to_a.map do |ignore_url|
      template = Addressable::URI.parse(ignore_url.name)
      template_hash = template.to_hash
      case ignore_url.kind
      when "start_with"
        if blank_request?(template_hash)
          # request_uri は未指定のため origin（特に authority）が start_with かどうかをチェック
          Matcher.host_start_with(name: ignore_url.name, template: template, template_hash: template_hash)
        else
          # origin は完全マッチ、request_uri が start_with かどうかをチェック
          Matcher.request_start_with(name: ignore_url.name, template: template, template_hash: template_hash)
        end
      when "end_with"
        if blank_request?(template_hash)
          # request_uri は未指定のため origin（特に authority）が end_with かどうかをチェック
          Matcher.host_end_with(name: ignore_url.name, template: template, template_hash: template_hash)
        else
          # origin は完全マッチ、request_uri が end_with かどうかをチェック
          Matcher.request_end_with(name: ignore_url.name, template: template, template_hash: template_hash)
        end
      when "include"
        if blank_request?(template_hash)
          # request_uri は未指定のため origin（特に authority）が include かどうかをチェック
          Matcher.host_include(name: ignore_url.name, template: template, template_hash: template_hash)
        else
          # origin は完全マッチ、request_uri が include かどうかをチェック
          Matcher.request_include(name: ignore_url.name, template: template, template_hash: template_hash)
        end
      else # "all"
        Matcher.exact(name: ignore_url.name, template: template, template_hash: template_hash)
      end
    end
  end

  def blank_request?(template_hash)
    (template_hash[:path].blank? || template_hash[:path] == "/") &&
      template_hash[:query].nil? &&
      template_hash[:fragment].nil?
  end
end
