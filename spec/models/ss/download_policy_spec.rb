require 'spec_helper'

describe SS::DownloadPolicy, dbscope: :example do
  let(:site) { cms_site }
  let(:user) { cms_user }

  before do
    @save_current_token = SS.current_token

    SS.current_site = nil
    SS.current_user = nil
    SS.current_user_group = nil
    SS.current_organization = nil
    SS.current_token = nil
  end

  after do
    SS.current_token = @save_current_token
  end

  context "empty setting" do
    before do
      @save_config = SS.config.replace_value_at(:ss, :download_policy, nil)
    end

    after do
      SS.config.replace_value_at(:ss, :download_policy, @save_config)
    end

    it do
      expect(SS::DownloadPolicy.download_policy).to be_nil

      SS.current_organization = user.organization
      expect(SS::DownloadPolicy.download_policy).to be_nil

      SS.current_organization.download_policy = 'disallowed'
      expect(SS::DownloadPolicy.download_policy).to be_nil

      SS.current_site = cms_site
      expect(SS::DownloadPolicy.download_policy).to be_nil

      SS.current_site.download_policy = 'disallowed'
      expect(SS::DownloadPolicy.download_policy).to be_nil
    end
  end

  context "disallowed setting" do
    before do
      @save_config = SS.config.replace_value_at(:ss, :download_policy, 'disallowed')
    end

    after do
      SS.config.replace_value_at(:ss, :download_policy, @save_config)
    end

    it do
      expect(SS::DownloadPolicy.download_policy).to eq 'disallowed'

      SS.current_organization = user.organization
      expect(SS::DownloadPolicy.download_policy).to eq 'disallowed'

      SS.current_organization.download_policy = 'none'
      expect(SS::DownloadPolicy.download_policy).to eq 'none'

      SS.current_organization.download_policy = 'disallowed'
      expect(SS::DownloadPolicy.download_policy).to eq 'disallowed'

      SS.current_site = site
      expect(SS::DownloadPolicy.download_policy).to eq 'disallowed'

      SS.current_site.download_policy = 'none'
      expect(SS::DownloadPolicy.download_policy).to eq 'none'

      SS.current_site.download_policy = 'disallowed'
      expect(SS::DownloadPolicy.download_policy).to eq 'disallowed'
    end
  end
end
