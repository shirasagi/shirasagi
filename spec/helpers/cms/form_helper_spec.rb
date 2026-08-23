require 'spec_helper'

describe Cms::FormHelper, type: :helper, dbscope: :example do
  describe "#ancestral_forms" do
    let!(:user) { cms_user }
    let!(:site0) { cms_site }
    let!(:site1) { create :cms_site_unique }
    let!(:site0_form) { create :cms_form, cur_site: site0, state: "public" }
    let!(:site1_form) { create :cms_form, cur_site: site1, state: "public" }

    before do
      user.add_to_set(group_ids: site1.id)
    end

    context "without node" do
      before do
        @cur_site = site0
        @cur_user = user
        @cur_path = "/index.html"
      end

      it do
        forms = helper.ancestral_forms
        expect(forms.count).to eq 1
        expect(forms.pluck(:name)).to include(site0_form.name)
      end
    end

    context "with article/node" do
      let!(:node) { create :article_node_page, cur_site: site0, st_form_ids: [ site0_form.id, site1_form ] }

      before do
        @cur_site = site0
        @cur_node = node
        @cur_user = user
        @cur_path = "/#{node.filename}/page1.html"
      end

      it do
        forms = helper.ancestral_forms
        expect(forms.count).to eq 1
        expect(forms.pluck(:name)).to include(site0_form.name)
      end
    end
  end

  describe "#ancestral_loop_settings" do
    let!(:user) { cms_user }
    let!(:site) { cms_site }
    let!(:shirasagi_setting) { create(:cms_loop_setting, site: site, html_format: "shirasagi", state: "public") }
    let!(:liquid_setting) { create(:cms_loop_setting, site: site, html_format: "liquid", state: "public") }
    let!(:closed_setting) { create(:cms_loop_setting, site: site, html_format: "shirasagi", state: "closed") }

    before do
      @cur_site = site
      @cur_user = user
    end

    it "returns only public shirasagi format loop settings" do
      settings = helper.ancestral_loop_settings
      expect(settings.count).to eq 1
      expect(settings.first[0]).to eq shirasagi_setting.name
      expect(settings.first[1]).to eq shirasagi_setting.id
    end

    it "does not include liquid format settings" do
      settings = helper.ancestral_loop_settings
      liquid_names = settings.map { |name, _id| name }
      expect(liquid_names).not_to include(liquid_setting.name)
    end

    it "does not include closed settings" do
      settings = helper.ancestral_loop_settings
      closed_names = settings.map { |name, _id| name }
      expect(closed_names).not_to include(closed_setting.name)
    end

    it "supplements a closed shirasagi setting" do
      settings = helper.ancestral_loop_settings(closed_setting)

      expect(settings).to include([closed_setting.name, closed_setting.id])
    end

    it "does not supplement a liquid setting" do
      settings = helper.ancestral_loop_settings(liquid_setting)

      expect(settings).not_to include([liquid_setting.name, liquid_setting.id])
    end

    # ループHTML設定はサイト管理者専用。権限の無いユーザーには選択肢を出さない。
    context "with a user who has no permission on loop settings" do
      let!(:restricted_role) { create(:cms_role, name: unique_id) }
      let!(:restricted_user) do
        create(:cms_user, name: unique_id, email: "#{unique_id}@example.jp", in_password: ss_pass,
          group_ids: [cms_group.id], cms_role_ids: [restricted_role.id])
      end

      before do
        @cur_user = restricted_user
      end

      it "returns no options" do
        expect(helper.ancestral_loop_settings).to eq []
      end

      # 現在適用中の設定だけは補完する。補完しないと select が空になり、
      # 保存時に既存の紐付けが意図せず解除されてしまう。
      it "supplements only the currently selected setting" do
        settings = helper.ancestral_loop_settings(shirasagi_setting)

        expect(settings).to eq [[shirasagi_setting.name, shirasagi_setting.id]]
      end
    end
  end

  describe "#liquid_loop_template_options" do
    let!(:user) { cms_user }
    let!(:site) { cms_site }
    let!(:liquid_setting) { create(:cms_loop_setting, :liquid, :template_type, site: site) }
    let!(:shirasagi_setting) { create(:cms_loop_setting, :shirasagi, :template_type, site: site) }
    let!(:closed_setting) { create(:cms_loop_setting, :liquid, :template_type, site: site, state: "closed") }
    let!(:snippet_setting) { create(:cms_loop_setting, :liquid, :snippet_type, site: site) }

    before do
      @cur_site = site
      @cur_user = user
    end

    it "does not supplement a shirasagi setting" do
      settings = helper.liquid_loop_template_options(shirasagi_setting)

      expect(settings).not_to include([shirasagi_setting.name, shirasagi_setting.id])
    end

    it "supplements a closed liquid setting" do
      settings = helper.liquid_loop_template_options(closed_setting)

      expect(settings).to include([closed_setting.name, closed_setting.id])
    end

    it "supplements a liquid snippet setting" do
      settings = helper.liquid_loop_template_options(snippet_setting)

      expect(settings).to include([snippet_setting.name, snippet_setting.id])
    end

    it "includes a public liquid template setting" do
      settings = helper.liquid_loop_template_options

      expect(settings).to include([liquid_setting.name, liquid_setting.id])
    end

    # ループHTML設定はサイト管理者専用。権限の無いユーザーには選択肢を出さない。
    context "with a user who has no permission on loop settings" do
      let!(:restricted_role) { create(:cms_role, name: unique_id) }
      let!(:restricted_user) do
        create(:cms_user, name: unique_id, email: "#{unique_id}@example.jp", in_password: ss_pass,
          group_ids: [cms_group.id], cms_role_ids: [restricted_role.id])
      end

      before do
        @cur_user = restricted_user
      end

      it "returns no options" do
        expect(helper.liquid_loop_template_options).to eq []
      end

      # 現在適用中の設定だけは補完する。補完しないと select が空になり、
      # 保存時に既存の紐付けが意図せず解除されてしまう。
      it "supplements only the currently selected setting" do
        settings = helper.liquid_loop_template_options(liquid_setting)

        expect(settings).to eq [[liquid_setting.name, liquid_setting.id]]
      end
    end
  end

  describe "snippet insertion helper functionality" do
    let!(:user) { cms_user }
    let!(:site) { cms_site }
    let(:liquid_html) { "{% for item in items %}<div class='item'>{{ item.name }}</div>{% endfor %}" }
    let(:shirasagi_html) { "<div class='item'>#{unique_id}</div>" }

    before do
      @cur_site = site
      @cur_user = user
    end

    describe "multiple shirasagi format settings" do
      let!(:shirasagi_setting1) do
        create(:cms_loop_setting,
          site: site,
          html_format: "shirasagi",
          html: shirasagi_html,
          state: "public",
          name: "Shirasagi Setting 1"
        )
      end
      let!(:shirasagi_setting2) do
        create(:cms_loop_setting,
          site: site,
          html_format: "shirasagi",
          html: shirasagi_html,
          state: "public",
          name: "Shirasagi Setting 2"
        )
      end

      it "returns all public shirasagi format settings" do
        settings = helper.ancestral_loop_settings
        expect(settings.count).to eq 2

        setting_names = settings.map { |name, _id| name }
        expect(setting_names).to include(shirasagi_setting1.name)
        expect(setting_names).to include(shirasagi_setting2.name)
      end
    end
  end
end
