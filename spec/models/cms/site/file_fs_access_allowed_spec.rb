require 'spec_helper'

describe Cms::Site, type: :model, dbscope: :example do
  let!(:site) { cms_site }

  describe "#file_fs_access_allowed?" do
    let(:ip_address) { %w(192.168.10.0/24) }
    let(:basic_auth_id) { unique_id }
    let(:basic_auth_password) { unique_id }
    let(:basic_auth_digest) { Base64.strict_encode64("#{basic_auth_id}:#{basic_auth_password}") }
    let(:env_key) { "X-SSL_CLIENT_S_DN_#{unique_id.upcase}" }
    let(:env_value) { "C=JP,O=JPNIC,OU=security,CN=#{unique_id}" }

    before do
      site.file_fs_access_restriction_state = "enabled"
      site.file_fs_access_restriction_allowed_ip_addresses = ip_address
      site.file_fs_access_restriction_basic_auth_id = basic_auth_id
      site.file_fs_access_restriction_basic_auth_password = SS::Crypto.encrypt(basic_auth_password)
      site.file_fs_access_restriction_env_key = env_key
      site.file_fs_access_restriction_env_value = env_value
      site.save!
    end

    it do
      ActionDispatch::Request.new("HTTP_X_REAL_IP" => "192.168.10.45").tap do |request|
        expect(site.file_fs_access_allowed?(request)).to be_truthy
      end
      ActionDispatch::Request.new("REMOTE_ADDR" => "192.168.10.32").tap do |request|
        expect(site.file_fs_access_allowed?(request)).to be_truthy
      end

      ActionDispatch::Request.new("HTTP_AUTHORIZATION" => "Basic #{basic_auth_digest}").tap do |request|
        expect(site.file_fs_access_allowed?(request)).to be_truthy
      end

      ActionDispatch::Request.new(env_key => env_value).tap do |request|
        expect(site.file_fs_access_allowed?(request)).to be_truthy
      end
    end
  end
end
