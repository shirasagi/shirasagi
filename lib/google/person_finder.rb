require 'builder'

class Google::PersonFinder
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

  PFIF_NS = 'http://zesty.ca/pfif/1.4'.freeze
  PFIF_BASIC_ATTRIBUTS = [:person_record_id, :entry_date, :expiry_date, :author_name, :author_email, :author_phone,
                          :source_name, :source_date, :source_url].freeze
  PFIF_SERACH_ATTRIBUTS = [:full_name, :given_name, :family_name, :alternate_names, :description, :sex,
                           :date_of_birth, :age, :home_street, :home_neighborhood, :home_city, :home_state,
                           :home_postal_code, :home_country, :photo_url, :profile_urls].freeze
  PFIF_NOTE_ATTRIBUTS = [:note_record_id, :person_record_id, :linked_person_record_id, :entry_date, :author_name,
                         :author_email, :author_phone, :source_date, :author_made_contact, :status,
                         :email_of_found_person, :phone_of_found_person, :last_known_location, :text, :photo_url].freeze

  def now
    @now ||= Time.zone.now
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

    def build_pfif(params)
      params = { entry_date: now }.merge(params)
      unless params[:person_record_id].start_with?("#{domain_name}/")
        params[:person_record_id] = "#{domain_name}/#{params[:person_record_id]}"
      end

      xml = ''
      builder = ::Builder::XmlMarkup.new(target: xml)

      builder.tag!('pfif', {'xmlns' => PFIF_NS}) do
        build_pfif_person(params, builder)
        build_pfif_note(params, builder)
      end

      xml
    end

    def build_pfif_person(params, builder)
      builder.person do
        # basic attributes
        PFIF_BASIC_ATTRIBUTS.each do |key|
          if v = params[key]
            v = v.utc.iso8601 if v.respond_to?(:utc)
            builder.tag!(key, v)
          end
        end

        # google pserson finder searches theres attributes
        PFIF_SERACH_ATTRIBUTS.each do |key|
          if v = params[key]
            v = v.utc.iso8601 if v.respond_to?(:utc)
            builder.tag!(key, v)
          end
        end
      end
    end

    def build_pfif_note(params, builder)
      return unless note_params = params[:note]

      note_params = note_params.dup
      note_params[:person_record_id] ||= params[:person_record_id]
      note_params[:entry_date] ||= now
      note_params[:source_date] ||= now
      if note_params[:note_record_id].blank?
        note_params[:note_record_id] = "#{params[:person_record_id]}.#{now.to_i}"
      end
      unless note_params[:note_record_id].start_with?("#{domain_name}/")
        note_params[:note_record_id] = "#{domain_name}/#{note_params[:note_record_id]}"
      end
      if note_params[:linked_person_record_id].present?
        unless note_params[:linked_person_record_id].start_with?("#{domain_name}/")
          note_params[:linked_person_record_id] = "#{domain_name}/#{note_params[:linked_person_record_id]}"
        end
      end

      builder.note do
        PFIF_NOTE_ATTRIBUTS.each do |key|
          if v = note_params[key]
            v = v.utc.iso8601 if v.respond_to?(:utc)
            builder.tag!(key, v)
          end
        end
      end
    end
end
