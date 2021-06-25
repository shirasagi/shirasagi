require 'spec_helper'

describe SS::UploadPolicy, dbscope: :example do
  let(:site) { cms_site }
  let(:user) { cms_user }

  before do
    SS.current_site = nil
    SS.current_user = nil
    SS.current_organization = nil
  end

  context "empty setting" do
    before do
      @save_config = SS.config.replace_value_at(:ss, :upload_policy, nil)
    end

    after do
      SS.config.replace_value_at(:ss, :upload_policy, @save_config)
    end

    it do
      expect(SS::UploadPolicy.upload_policy).to be_nil

      SS.current_organization = user.organization
      expect(SS::UploadPolicy.upload_policy).to be_nil

      SS.current_site = cms_site
      expect(SS::UploadPolicy.upload_policy).to be_nil
    end
  end

  context "sanitizer setting" do
    before do
      @save_config = SS.config.replace_value_at(:ss, :upload_policy, 'sanitizer')
    end

    after do
      SS.config.replace_value_at(:ss, :upload_policy, @save_config)
    end

    it do
      expect(SS::UploadPolicy.upload_policy).to eq 'sanitizer'

      SS.current_organization = user.organization
      expect(SS::UploadPolicy.upload_policy).to eq 'sanitizer'

      SS.current_organization.upload_policy = 'sanitizer'
      expect(SS::UploadPolicy.upload_policy).to eq 'sanitizer'

      SS.current_organization.upload_policy = 'restricted'
      expect(SS::UploadPolicy.upload_policy).to eq 'restricted'

      SS.current_site = site
      expect(SS::UploadPolicy.upload_policy).to eq 'sanitizer'

      SS.current_site.upload_policy = 'sanitizer'
      expect(SS::UploadPolicy.upload_policy).to eq 'sanitizer'

      SS.current_site.upload_policy = 'restricted'
      expect(SS::UploadPolicy.upload_policy).to eq 'restricted'
    end
  end
end
