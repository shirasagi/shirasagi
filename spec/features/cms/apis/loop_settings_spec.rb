require 'spec_helper'

describe "cms_apis_loop_settings", type: :feature, dbscope: :example do
  let!(:site) { cms_site }
  let(:shirasagi_html) { "<div class='item'>#{unique_id}</div>" }
  let(:liquid_html) { "{% for item in items %}<div>{{ item.name }}</div>{% endfor %}" }

  let!(:shirasagi_setting) do
    create(:cms_loop_setting, :shirasagi, :template_type,
      site: site, state: 'public',
      name: "shirasagi-#{unique_id}", html: shirasagi_html)
  end
  let!(:liquid_setting) do
    create(:cms_loop_setting, :liquid, :template_type,
      site: site, state: 'public',
      name: "liquid-#{unique_id}", html: liquid_html)
  end

  context "with auth" do
    before { login_cms_user }

    describe "#show" do
      context "when shirasagi format loop_setting is requested" do
        it "returns 200 with html in JSON" do
          visit "#{cms_apis_loop_setting_path(site: site.id, id: shirasagi_setting.id)}.json"

          expect(status_code).to eq 200
          json = JSON.parse(page.source)
          expect(json).to include("html" => shirasagi_html)
        end
      end

      context "when liquid format loop_setting is requested" do
        it "returns 200 with liquid html in JSON" do
          visit "#{cms_apis_loop_setting_path(site: site.id, id: liquid_setting.id)}.json"

          expect(status_code).to eq 200
          json = JSON.parse(page.source)
          expect(json).to include("html" => liquid_html)
        end
      end

      context "when html is empty" do
        let!(:empty_setting) do
          create(:cms_loop_setting, :liquid, :template_type,
            site: site, state: 'public',
            name: "empty-#{unique_id}", html: "")
        end

        # NOTE: Mongoid converts blank string to nil on save, so the API returns
        # { "html": null }. The JS loader (loop_setting_loader.js) is aware of this
        # contract and converts null to "" before assigning to the editor.
        it "returns 200 with html as null in JSON" do
          visit "#{cms_apis_loop_setting_path(site: site.id, id: empty_setting.id)}.json"

          expect(status_code).to eq 200
          json = JSON.parse(page.source)
          expect(json).to have_key("html")
          expect(json["html"]).to be_nil
        end
      end

      context "when state is closed" do
        let!(:closed_setting) do
          create(:cms_loop_setting, :liquid, :template_type,
            site: site, state: 'closed',
            name: "closed-#{unique_id}", html: liquid_html)
        end

        it "returns 200 (controller does not filter by state)" do
          visit "#{cms_apis_loop_setting_path(site: site.id, id: closed_setting.id)}.json"

          expect(status_code).to eq 200
          json = JSON.parse(page.source)
          expect(json).to include("html" => liquid_html)
        end
      end

      context "when non-existent id is requested" do
        it "returns 404" do
          visit "#{cms_apis_loop_setting_path(site: site.id, id: 0)}.json"

          expect(status_code).to eq 404
        end
      end

      context "when loop_setting belongs to another site" do
        let!(:other_site) { create(:cms_site_unique, group_ids: [cms_group.id]) }
        let!(:other_setting) do
          create(:cms_loop_setting, :liquid, :template_type,
            site: other_site, state: 'public',
            name: "other-#{unique_id}", html: liquid_html)
        end

        it "returns 404" do
          visit "#{cms_apis_loop_setting_path(site: site.id, id: other_setting.id)}.json"

          expect(status_code).to eq 404
        end
      end
    end
  end

  context "without auth" do
    it "redirects to login page" do
      visit cms_apis_loop_setting_path(site: site.id, id: shirasagi_setting.id)
      expect(current_path).to eq sns_login_path
    end
  end
end
