require 'builder'

class Google::PersonFinder
  include Google::PfifBuilder

  attr_accessor :repository
  attr_accessor :api_key
  attr_accessor :domain_name
  attr_accessor :timeout, :open_timeout

  def initialize(params = {})
    @repository = params[:repository].presence || 'test'
    @api_key = params[:api_key].presence || '43HxMWGBijFaYEr5'
    @domain_name = params[:domain_name].presence || 'testkey.personfinder.google.org'
  end

  def base_uri
    URI.parse("https://www.google.org/personfinder/#{repository}")
  end

  def get_uri(params)
    query = {
      key: api_key,
      id: "#{domain_name}/#{params[:person_record_id]}"
    }
    URI.parse("https://www.google.org/personfinder/#{repository}/api/search?#{query.to_param}")
  end

  def search_uri(params)
    query = {
      key: api_key,
      q: params[:q]
    }
    URI.parse("https://www.google.org/personfinder/#{repository}/api/search?#{query.to_param}")
  end

  def upload_uri
    query = {
      key: api_key,
    }
    URI.parse("https://www.google.org/personfinder/#{repository}/api/write?#{query.to_param}")
  end

  def view_uri(params)
    query = {
      lang: :ja,
      id: "#{domain_name}/#{params[:person_record_id]}"
    }
    URI.parse("https://www.google.org/personfinder/#{repository}/view?#{query.to_param}")
  end

  def feed_uri
    URI.parse("https://www.google.org/personfinder/#{repository}/feeds/repo")
  end

  def get(params)
    uri = get_uri(params)
    c = connection(uri)
    res = c.get("#{uri.path}?#{uri.query}") do |req|
      req.options.timeout = timeout if timeout.present?
      req.options.open_timeout = open_timeout if open_timeout.present?
    end

    return nil if res.status != 200

    body = res.body.presence
    body = Hash.from_xml(body) if body.present?
    body
  end

  def search(params)
    uri = search_uri(params)
    c = connection(uri)
    res = c.get("#{uri.path}?#{uri.query}") do |req|
      req.options.timeout = timeout if timeout.present?
      req.options.open_timeout = open_timeout if open_timeout.present?
    end

    return nil if res.status != 200

    body = res.body.presence
    body = Hash.from_xml(body) if body.present?
    body
  end

  def mode
    uri = feed_uri
    c = connection(uri)
    res = c.get("#{uri.path}?#{uri.query}") do |req|
      req.options.timeout = timeout if timeout.present?
      req.options.open_timeout = open_timeout if open_timeout.present?
    end

    return :unknown if res.status != 200

    body = res.body.presence
    xmldoc = REXML::Document.new(body)
    return :unknown unless REXML::XPath.first(xmldoc, '/feed/entry/content/gpf:repo')

    test_mode = REXML::XPath.first(xmldoc, '/feed/entry/content/gpf:repo/gpf:test_mode/text()')
    return :test if test_mode == 'true'
    :normal
  end

  def upload(params = {})
    raise 'some required attributes are missing' if [:person_record_id, :full_name].find { |key| params[key].present? }.blank?

    xml = build_pfif(params)

    uri = upload_uri
    c = connection(uri)
    res = c.post("#{uri.path}?#{uri.query}") do |req|
      req.options.timeout = timeout if timeout.present?
      req.options.open_timeout = open_timeout if open_timeout.present?
      req.headers['Content-Type'] = 'application/pfif+xml'
      req.body = xml
    end

    return nil if res.status != 200
    true
  end

  private
    def connection(uri)
      c = Faraday.new(:url => uri.to_s) do |builder|
        builder.request :url_encoded
        builder.response :logger, Rails.logger
        builder.adapter Faraday.default_adapter
      end
      c.headers[:user_agent] += " (Shirasagi/#{SS.version}; PID/#{Process.pid})"
      c
    end
end
