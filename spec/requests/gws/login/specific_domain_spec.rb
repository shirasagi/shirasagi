require 'spec_helper'

describe "Gws::LoginController#login", type: :request, dbscope: :example do
  let!(:site0) { gws_site }
  let!(:site1) { create :gws_group }
  let!(:site2) { create :gws_group }
  let(:domain1) { "#{unique_id}.example.jp" }
  let(:domain2) { "#{unique_id}.example.jp" }

  before do
    site1.domains = domain1
    site1.save!

    site2.domains = domain2
    site2.save!
  end

  context "when domain1 with http is given" do
    it do
      get "http://#{domain1}/"
      expect(response.status).to eq 302
      expect(response.location).to eq "//#{domain1}#{gws_login_path(site: site1)}"
    end
  end

  context "when domain2 with http2 is given" do
    it do
      get "https://#{domain2}/"
      expect(response.status).to eq 302
      expect(response.location).to eq "//#{domain2}#{gws_login_path(site: site2)}"
    end
  end
end
