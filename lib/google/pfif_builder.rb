module Google::PfifBuilder
  extend ActiveSupport::Concern

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
