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
    let!(:liquid_setting) { create(:cms_loop_setting, site: site, html_format: "liquid", state: "public", name: "ループHTML設定") }
    let!(:liquid_setting_snippet) do
      create(:cms_loop_setting, site: site, html_format: "liquid", state: "public", setting_type: "snippet", name: "スニペット/テストスニペット")
    end
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

    context "with liquid format" do
      it "returns liquid format settings that are not snippet type" do
        settings = helper.ancestral_loop_settings("liquid")
        setting_names = settings.map { |name, _id| name }
        expect(setting_names).to include(liquid_setting.name)
        expect(setting_names).not_to include(liquid_setting_snippet.name)
      end

      it "includes description in returned settings" do
        liquid_setting_with_description = create(:cms_loop_setting,
          site: site,
          html_format: "liquid",
          state: "public",
          name: "ループHTML設定（説明付き）",
          description: "これは説明です"
        )
        settings = helper.ancestral_loop_settings("liquid")
        setting_with_desc = settings.find { |name, _id| name == liquid_setting_with_description.name }
        expect(setting_with_desc).to be_present
        expect(setting_with_desc[2]).to eq "これは説明です"
      end
    end
  end

  describe "#ancestral_html_settings_liquid" do
    let!(:user) { cms_user }
    let!(:site) { cms_site }
    let!(:shirasagi_setting) { create(:cms_loop_setting, site: site, html_format: "shirasagi", state: "public") }
    let!(:liquid_setting) do
      create(:cms_loop_setting, site: site, html_format: "liquid", state: "public", setting_type: "snippet", name: "スニペット/テストスニペット")
    end
    let!(:liquid_setting_non_snippet) do
      create(:cms_loop_setting, site: site, html_format: "liquid", state: "public", setting_type: "template", name: "ループHTML設定")
    end
    let!(:closed_setting) do
      create(:cms_loop_setting, site: site, html_format: "liquid", state: "closed", setting_type: "snippet", name: "スニペット/クローズドスニペット")
    end

    before do
      @cur_site = site
      @cur_user = user
    end

    it "returns only public liquid format loop settings that are snippet type" do
      settings = helper.ancestral_html_settings_liquid
      expect(settings.count).to eq 1
      expect(settings.first[0]).to eq liquid_setting.name
      expect(settings.first[1]).to eq liquid_setting.id
      expect(settings.first[2]).to include("data-snippet" => liquid_setting.html)
    end

    it "does not include shirasagi format settings" do
      settings = helper.ancestral_html_settings_liquid
      shirasagi_names = settings.map { |name, _id| name }
      expect(shirasagi_names).not_to include(shirasagi_setting.name)
    end

    it "does not include closed settings" do
      settings = helper.ancestral_html_settings_liquid
      closed_names = settings.map { |name, _id| name }
      expect(closed_names).not_to include(closed_setting.name)
    end

    it "does not include non-snippet liquid settings" do
      settings = helper.ancestral_html_settings_liquid
      setting_names = settings.map { |name, _id| name }
      expect(setting_names).not_to include(liquid_setting_non_snippet.name)
    end

    it "includes description in returned settings when present" do
      liquid_setting_with_description = create(:cms_loop_setting,
        site: site,
        html_format: "liquid",
        state: "public",
        setting_type: "snippet",
        name: "スニペット/テストスニペット（説明付き）",
        description: "これはスニペットの説明です"
      )
      settings = helper.ancestral_html_settings_liquid
      setting_with_desc = settings.find { |name, _id| name == liquid_setting_with_description.name }
      expect(setting_with_desc).to be_present
      expect(setting_with_desc[2]).to include("data-snippet" => liquid_setting_with_description.html)
      expect(setting_with_desc[2]).to include("data-description" => "これはスニペットの説明です")
    end

    it "does not include description key when description is blank" do
      liquid_setting_no_description = create(:cms_loop_setting,
        site: site,
        html_format: "liquid",
        state: "public",
        setting_type: "snippet",
        name: "スニペット/テストスニペット（説明なし）",
        description: nil
      )
      settings = helper.ancestral_html_settings_liquid
      setting_no_desc = settings.find { |name, _id| name == liquid_setting_no_description.name }
      expect(setting_no_desc).to be_present
      expect(setting_no_desc[2]).to include("data-snippet" => liquid_setting_no_description.html)
      expect(setting_no_desc[2]).not_to have_key("data-description")
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

    describe "multiple liquid format settings" do
      let!(:liquid_setting1) do
        create(:cms_loop_setting,
          site: site,
          html_format: "liquid",
          html: liquid_html,
          state: "public",
          setting_type: "snippet",
          name: "スニペット/Liquid Setting 1"
        )
      end
      let!(:liquid_setting2) do
        create(:cms_loop_setting,
          site: site,
          html_format: "liquid",
          html: liquid_html,
          state: "public",
          setting_type: "snippet",
          name: "スニペット/Liquid Setting 2"
        )
      end
      let!(:liquid_setting_non_snippet) do
        create(:cms_loop_setting,
          site: site,
          html_format: "liquid",
          html: liquid_html,
          state: "public",
          setting_type: "template",
          name: "Liquid Setting Non Snippet"
        )
      end

      it "returns all public liquid format settings that are snippet type" do
        settings = helper.ancestral_html_settings_liquid
        expect(settings.count).to eq 2

        setting_names = settings.map { |name, _id| name }
        expect(setting_names).to include(liquid_setting1.name)
        expect(setting_names).to include(liquid_setting2.name)
        expect(setting_names).not_to include(liquid_setting_non_snippet.name)
      end

      it "returns settings in correct format for select options" do
        settings = helper.ancestral_html_settings_liquid
        expect(settings.first).to be_an(Array)
        expect(settings.first.length).to eq 3
        expect(settings.first[0]).to be_a(String) # name
        expect(settings.first[1]).to be_a(Integer)
        expect(settings.first[2]).to include("data-snippet" => a_kind_of(String))
      end
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

    describe "mixed format settings" do
      let!(:liquid_setting_snippet) do
        create(:cms_loop_setting,
          site: site,
          html_format: "liquid",
          html: liquid_html,
          state: "public",
          setting_type: "snippet",
          name: "スニペット/Liquid Setting"
        )
      end
      let!(:liquid_setting_non_snippet) do
        create(:cms_loop_setting,
          site: site,
          html_format: "liquid",
          html: liquid_html,
          state: "public",
          setting_type: "template",
          name: "Liquid Setting Non Snippet"
        )
      end
      let!(:shirasagi_setting) do
        create(:cms_loop_setting,
          site: site,
          html_format: "shirasagi",
          html: shirasagi_html,
          state: "public",
          name: "Shirasagi Setting"
        )
      end

      it "correctly separates snippet and loop settings" do
        snippet_settings = helper.ancestral_html_settings_liquid
        loop_settings = helper.ancestral_loop_settings
        loop_settings_liquid = helper.ancestral_loop_settings("liquid")

        snippet_names = snippet_settings.map { |name, _id| name }
        loop_names = loop_settings.map { |name, _id| name }
        loop_liquid_names = loop_settings_liquid.map { |name, _id| name }

        expect(snippet_names).to include(liquid_setting_snippet.name)
        expect(snippet_names).not_to include(liquid_setting_non_snippet.name)
        expect(snippet_names).not_to include(shirasagi_setting.name)
        expect(loop_names).to include(shirasagi_setting.name)
        expect(loop_names).not_to include(liquid_setting_snippet.name)
        expect(loop_names).not_to include(liquid_setting_non_snippet.name)
        expect(loop_liquid_names).to include(liquid_setting_non_snippet.name)
        expect(loop_liquid_names).not_to include(liquid_setting_snippet.name)
      end
    end

    describe "empty results" do
      it "returns empty array when no settings exist" do
        # Clear all loop settings for this site
        Cms::LoopSetting.site(site).destroy_all

        liquid_settings = helper.ancestral_html_settings_liquid
        shirasagi_settings = helper.ancestral_loop_settings

        expect(liquid_settings).to be_empty
        expect(shirasagi_settings).to be_empty
      end

      it "returns empty array when only closed settings exist" do
        # Clear all loop settings for this site
        Cms::LoopSetting.site(site).destroy_all

        # Create only closed settings
        create(:cms_loop_setting, site: site, html_format: "liquid", state: "closed")
        create(:cms_loop_setting, site: site, html_format: "shirasagi", state: "closed")

        liquid_settings = helper.ancestral_html_settings_liquid
        shirasagi_settings = helper.ancestral_loop_settings

        expect(liquid_settings).to be_empty
        expect(shirasagi_settings).to be_empty
      end
    end
  end

  describe "#options_with_optgroup_for_loop_settings" do
    let!(:user) { cms_user }
    let!(:site) { cms_site }

    before do
      @cur_site = site
      @cur_user = user
    end

    context "with description" do
      it "includes data-description attribute in option tags" do
        items = [
          ["テスト設定", 1, "これは説明です"],
          ["グループ/子設定", 2, "子設定の説明"]
        ]
        html = helper.options_with_optgroup_for_loop_settings(items)
        doc = Nokogiri::HTML::DocumentFragment.parse(html)

        # 直接入力オプションを確認
        direct_input = doc.css('option[value=""]').first
        expect(direct_input).to be_present
        expect(direct_input.text).to include("直接入力")

        # 説明付きオプションを確認
        option_with_desc = doc.css('option[value="1"]').first
        expect(option_with_desc).to be_present
        expect(option_with_desc.text).to eq "テスト設定"
        expect(option_with_desc['data-description']).to eq "これは説明です"

        # グループ内のオプションを確認
        optgroup = doc.css('optgroup[label="グループ"]').first
        expect(optgroup).to be_present
        option_in_group = optgroup.css('option[value="2"]').first
        expect(option_in_group).to be_present
        expect(option_in_group.text).to eq "子設定"
        expect(option_in_group['data-description']).to eq "子設定の説明"
      end

      it "does not include data-description attribute when description is blank" do
        items = [
          ["テスト設定", 1, nil],
          ["テスト設定2", 2, ""]
        ]
        html = helper.options_with_optgroup_for_loop_settings(items)
        doc = Nokogiri::HTML::DocumentFragment.parse(html)

        option1 = doc.css('option[value="1"]').first
        expect(option1).to be_present
        expect(option1['data-description']).to be_nil

        option2 = doc.css('option[value="2"]').first
        expect(option2).to be_present
        expect(option2['data-description']).to be_nil
      end

      it "maintains backward compatibility with items without description" do
        items = [
          ["テスト設定", 1],
          ["グループ/子設定", 2]
        ]
        html = helper.options_with_optgroup_for_loop_settings(items)
        doc = Nokogiri::HTML::DocumentFragment.parse(html)

        option1 = doc.css('option[value="1"]').first
        expect(option1).to be_present
        expect(option1.text).to eq "テスト設定"
        expect(option1['data-description']).to be_nil
      end
    end
  end

  describe "#options_with_optgroup_for_snippets" do
    let!(:user) { cms_user }
    let!(:site) { cms_site }

    before do
      @cur_site = site
      @cur_user = user
    end

    context "with description" do
      it "includes data-description attribute in option tags" do
        items = [
          ["スニペット/テストスニペット", 1, { "data-snippet" => "{{ test }}", "data-description" => "これは説明です" }],
          ["スニペット/グループ/子スニペット", 2, { "data-snippet" => "{{ child }}", "data-description" => "子スニペットの説明" }]
        ]
        html = helper.options_with_optgroup_for_snippets(items)
        doc = Nokogiri::HTML::DocumentFragment.parse(html)

        # 直接入力オプションを確認
        direct_input = doc.css('option[value=""]').first
        expect(direct_input).to be_present
        expect(direct_input.text).to include("直接入力")

        # 説明付きオプションを確認（グループ化される）
        option_with_desc = doc.css('option[value="1"]').first
        expect(option_with_desc).to be_present
        expect(option_with_desc.text).to eq "テストスニペット"
        expect(option_with_desc['data-snippet']).to eq "{{ test }}"
        expect(option_with_desc['data-description']).to eq "これは説明です"

        # グループ内のオプションを確認
        optgroup = doc.css('optgroup[label="スニペット"]').first
        expect(optgroup).to be_present
        option_in_group = optgroup.css('option[value="2"]').first
        expect(option_in_group).to be_present
        expect(option_in_group.text).to eq "グループ/子スニペット"
        expect(option_in_group['data-snippet']).to eq "{{ child }}"
        expect(option_in_group['data-description']).to eq "子スニペットの説明"
      end

      it "does not include data-description attribute when description is blank" do
        items = [
          ["スニペット/テストスニペット", 1, { "data-snippet" => "{{ test }}" }]
        ]
        html = helper.options_with_optgroup_for_snippets(items)
        doc = Nokogiri::HTML::DocumentFragment.parse(html)

        option = doc.css('option[value="1"]').first
        expect(option).to be_present
        expect(option['data-snippet']).to eq "{{ test }}"
        expect(option['data-description']).to be_nil
      end
    end
  end
end
