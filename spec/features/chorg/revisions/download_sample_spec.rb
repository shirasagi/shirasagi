require 'spec_helper'

describe "chorg_import_revision", type: :feature, dbscope: :example do
  let!(:site) { cms_site }
  let!(:revision) { create(:revision, cur_site: site) }

  before { login_cms_user }

  describe "#download_sample_csv" do
    it do
      visit chorg_revision_path(site: site, id: revision)
      click_on I18n.t("ss.links.import_csv")
      click_on I18n.t("ss.links.download_sample_csv")

      expect(page.response_headers['Content-Type']).to eq("text/csv; charset=utf-8")
      csv_source = ::SS::ChunkReader.new(page.html).to_a.join
      csv_source.force_encoding("UTF-8")
      header = CSV.parse(csv_source[1..-1]).first

      expect(header).to include I18n.t("chorg.import.changeset.type")
      expect(header).to include I18n.t("chorg.import.changeset.source")
      expect(header).to include I18n.t("chorg.import.changeset.nth_destination_name", dest_seq: 1)
      expect(header).to include I18n.t("chorg.import.changeset.nth_destination_order", dest_seq: 1)
      expect(header).to include I18n.t("chorg.import.changeset.nth_destination_ldap_dn", dest_seq: 1)
      expect(header).to include I18n.t("chorg.import.changeset.nth_destination_contact_main_state", dest_seq: 1, contact_seq: 1)
    end
  end
end
