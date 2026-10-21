require 'spec_helper'

describe "/.mypage/login/saml/:id/init", dbscope: :example, type: :request do
  let(:metadata_file) { "#{Rails.root}/spec/fixtures/sys/auth/metadata-1.xml" }
  let(:filename) { unique_id }

  before do
    Fs::UploadedFile.create_from_file(metadata_file, basename: "spec") do |file|
      saml = Sys::Auth::Saml.new
      saml.name = unique_id
      saml.filename = filename
      saml.in_metadata = file
      saml.authn_context = authn_context
      saml.save!
    end
  end

  def requested_authn_context_class_refs
    get sns_login_saml_path(id: filename)
    expect(response.status).to eq 302

    query = Rack::Utils.parse_query(URI.parse(response.location).query)
    xml = Zlib::Inflate.new(-Zlib::MAX_WBITS).inflate(Base64.decode64(query["SAMLRequest"]))
    doc = REXML::Document.new(xml)
    return if REXML::XPath.first(doc, "//samlp:RequestedAuthnContext").nil?

    REXML::XPath.match(doc, "//saml:AuthnContextClassRef").map(&:text)
  end

  context "when authn_context is blank" do
    let(:authn_context) { nil }

    it do
      expect(requested_authn_context_class_refs).to eq [ Sys::Auth::Saml::DEFAULT_AUTHN_CONTEXT ]
    end
  end

  context "when authn_context is password_protected_transport" do
    let(:authn_context) { "password_protected_transport" }

    it do
      expect(requested_authn_context_class_refs).to eq %w(urn:oasis:names:tc:SAML:2.0:ac:classes:PasswordProtectedTransport)
    end
  end

  context "when authn_context is windows" do
    let(:authn_context) { "windows" }

    it do
      expect(requested_authn_context_class_refs).to eq %w(urn:federation:authentication:windows)
    end
  end

  context "when authn_context is none" do
    let(:authn_context) { "none" }

    it do
      expect(requested_authn_context_class_refs).to be_nil
    end
  end
end
