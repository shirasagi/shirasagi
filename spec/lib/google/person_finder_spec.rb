require 'spec_helper'

describe Google::PersonFinder, dbscope: :example do
  let(:person_record_id) { SecureRandom.uuid.to_s }
  let(:expiry_date) { Time.zone.now }
  let(:author_name) { unique_id }
  let(:author_email) { "#{author_name}@example.jp" }
  let(:author_phone) { "03-0000-0000" }
  let(:source_name) { unique_id }
  let(:source_date) { Time.zone.now }
  let(:source_url) { "http://#{source_name}.example.jp/" }
  let(:full_name) { unique_id }
  let(:given_name) { unique_id }
  let(:family_name) { unique_id }
  let(:alternate_names) { "#{unique_id}\n#{unique_id}" }
  let(:description) { unique_id }
  let(:sex) { %w(male, female).sample }
  let(:date_of_birth) { "1985-01-01" }
  let(:age) { "35-36" }
  let(:home_street) { unique_id }
  let(:home_neighborhood) { unique_id }
  let(:home_city) { unique_id }
  let(:home_state) { unique_id }
  let(:home_postal_code) { unique_id }
  let(:home_country) { "ja" }
  let(:profile_urls) { "http://#{unique_id}.example.jp/\nhttp://#{unique_id}.example.jp/" }
  let(:linked_person_record_id) { SecureRandom.uuid.to_s }
  let(:author_made_contact) { %w(true false).sample }
  let(:status) do
    if author_made_contact == "true"
      %w(information_sought is_note_author believed_alive believed_missing).sample
    else
      %w(information_sought believed_alive believed_missing).sample
    end
  end
  let(:email_of_found_person) { "#{unique_id}@example.jp" }
  let(:phone_of_found_person) { "06-9999-9999" }
  let(:last_known_location) { "大阪府大阪市北区中之島1丁目" }
  let(:text) { unique_id }
  let(:photo_url) { "http://#{unique_id}.example.jp/" }
  let(:params) do
    {
      person_record_id: person_record_id,
      expiry_date: expiry_date,
      author_name: author_name,
      author_email: author_email,
      author_phone: author_phone,
      source_name: source_name,
      source_date: source_date,
      source_url: source_url,
      full_name: full_name,
      given_name: given_name,
      family_name: family_name,
      alternate_names: alternate_names,
      description: description,
      sex: sex,
      date_of_birth: date_of_birth,
      age: age,
      home_street: home_street,
      home_neighborhood: home_neighborhood,
      home_city: home_city,
      home_state: home_state,
      home_postal_code: home_postal_code,
      home_country: home_country,
      photo_url: photo_url,
      profile_urls: profile_urls,
      note: {
        linked_person_record_id: linked_person_record_id,
        author_name: author_name,
        author_email: author_email,
        author_phone: author_phone,
        source_date: source_date,
        author_made_contact: author_made_contact,
        status: status,
        email_of_found_person: email_of_found_person,
        phone_of_found_person: phone_of_found_person,
        last_known_location: last_known_location,
        text: text,
        photo_url: photo_url,
      }
    }
  end

  after(:all) do
    WebMock.reset!
  end

  describe "#get" do
    subject { described_class.new.get(person_record_id: SecureRandom.uuid) }
    it do
      expect(subject["pfif"]).not_to be_nil
    end
  end

  describe "#search" do
    subject { described_class.new.get(q: 'test') }
    it do
      expect(subject["pfif"]).not_to be_nil
    end
  end

  describe "#mode" do
    subject { described_class.new.mode }
    let(:repo_url) do
      "https://www.google.org/personfinder/test/feeds/repo"
    end

    before do
      stub_request(:get, repo_url).
        to_return(body: response, status: 200, headers: { 'Content-Type' => 'application/xml' })
    end

    context "when test repository" do
      let(:response) { File.read(Rails.root.join('spec', 'fixtures', 'google', 'repository-feed-test.xml')) }
      it do
        expect(subject).to be :unknown
      end
    end

    context "when japan repository which mode is in test" do
      let(:response) { File.read(Rails.root.join('spec', 'fixtures', 'google', 'repository-feed-japan-test.xml')) }
      it do
        expect(subject).to be :test
      end
    end

    context "when japan repository which mode is not in test" do
      let(:response) { File.read(Rails.root.join('spec', 'fixtures', 'google', 'repository-feed-japan-normal.xml')) }
      it do
        expect(subject).to be :normal
      end
    end
  end

  describe "#upload" do
    let(:response) { File.read(Rails.root.join('spec', 'fixtures', 'google', 'person-finder-error.xml')) }
    let(:item) { described_class.new }
    let(:ptf_url) do
      "https://www.google.org/personfinder/#{item.repository}/api/write?#{{key: item.api_key}.to_param}"
    end
    subject { described_class.new.upload(params) }

    before do
      stub_request(:post, ptf_url).
        to_return(body: response, status: 200, headers: { 'Content-Type' => 'application/xml' })
    end

    it do
      # get true always
      expect(subject).to be_truthy
    end
  end

  describe "#build_pfif" do
    let(:item) { described_class.new }
    subject { REXML::Document.new(item.send(:build_pfif, params)) }

    def xpath(*paths)
      ns = { 'pfif' => 'http://zesty.ca/pfif/1.4' }
      path = "/" + paths.map { |p| "pfif:#{p}"}.join("/") + "/text()"
      REXML::XPath.first(subject, path, ns).to_s
    end

    it do
      # person information
      expect(xpath('pfif', 'person', 'person_record_id')).to eq "#{item.domain_name}/#{person_record_id}"
      expect(xpath('pfif', 'person', 'entry_date')).not_to be_nil
      expect(xpath('pfif', 'person', 'expiry_date')).to eq expiry_date.utc.iso8601
      expect(xpath('pfif', 'person', 'author_name')).to eq author_name
      expect(xpath('pfif', 'person', 'author_email')).to eq author_email
      expect(xpath('pfif', 'person', 'author_phone')).to eq author_phone
      expect(xpath('pfif', 'person', 'source_name')).to eq source_name
      expect(xpath('pfif', 'person', 'source_date')).to eq source_date.utc.iso8601
      expect(xpath('pfif', 'person', 'source_url')).to eq source_url
      expect(xpath('pfif', 'person', 'full_name')).to eq full_name
      expect(xpath('pfif', 'person', 'given_name')).to eq given_name
      expect(xpath('pfif', 'person', 'family_name')).to eq family_name
      expect(xpath('pfif', 'person', 'alternate_names')).to eq alternate_names
      expect(xpath('pfif', 'person', 'description')).to eq description
      expect(xpath('pfif', 'person', 'sex')).to eq sex
      expect(xpath('pfif', 'person', 'date_of_birth')).to eq date_of_birth
      expect(xpath('pfif', 'person', 'age')).to eq age
      expect(xpath('pfif', 'person', 'home_street')).to eq home_street
      expect(xpath('pfif', 'person', 'home_neighborhood')).to eq home_neighborhood
      expect(xpath('pfif', 'person', 'home_city')).to eq home_city
      expect(xpath('pfif', 'person', 'home_state')).to eq home_state
      expect(xpath('pfif', 'person', 'home_postal_code')).to eq home_postal_code
      expect(xpath('pfif', 'person', 'home_country')).to eq home_country
      expect(xpath('pfif', 'person', 'photo_url')).to eq photo_url
      expect(xpath('pfif', 'person', 'profile_urls')).to eq profile_urls

      # note of person information
      expect(xpath('pfif', 'note', 'note_record_id')).to start_with "#{item.domain_name}/#{person_record_id}"
      expect(xpath('pfif', 'note', 'person_record_id')).to eq "#{item.domain_name}/#{person_record_id}"
      expect(xpath('pfif', 'note', 'linked_person_record_id')).to eq "#{item.domain_name}/#{linked_person_record_id}"
      expect(xpath('pfif', 'note', 'entry_date')).not_to be_nil
      expect(xpath('pfif', 'note', 'author_name')).to eq author_name
      expect(xpath('pfif', 'note', 'author_email')).to eq author_email
      expect(xpath('pfif', 'note', 'author_phone')).to eq author_phone
      expect(xpath('pfif', 'note', 'source_date')).to eq source_date.utc.iso8601
      expect(xpath('pfif', 'note', 'author_made_contact')).to eq author_made_contact
      expect(xpath('pfif', 'note', 'status')).to eq status
      expect(xpath('pfif', 'note', 'email_of_found_person')).to eq email_of_found_person
      expect(xpath('pfif', 'note', 'phone_of_found_person')).to eq phone_of_found_person
      expect(xpath('pfif', 'note', 'last_known_location')).to eq last_known_location
      expect(xpath('pfif', 'note', 'text')).to eq text
      expect(xpath('pfif', 'note', 'photo_url')).to eq photo_url
    end
  end
end
