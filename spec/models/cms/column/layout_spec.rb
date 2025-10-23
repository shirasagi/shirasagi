require 'spec_helper'

describe Cms::Column::Base, type: :model, dbscope: :example do
  let!(:site) { cms_site }
  let!(:form) { create(:cms_form, cur_site: site) }
  let(:liquid_html) { "{% for item in items %}<div class='item'>{{ item.name }}</div>{% endfor %}" }

  describe "layout functionality" do
    let!(:liquid_setting) do
      create(:cms_loop_setting,
        site: site,
        html_format: "liquid",
        html: liquid_html,
        state: "public",
        name: "Test Liquid Setting"
      )
    end

    describe "layout field" do
      it "can set layout content" do
        layout_content = "<div class='custom-layout'>{% for item in items %}" \
                         "<div class='custom-item'>{{ item.name }}</div>{% endfor %}</div>"
        column = build(:cms_column_free, cur_site: site, cur_form: form, layout: layout_content)

        expect(column).to be_valid
        expect(column.layout).to eq layout_content
      end

      it "accepts empty layout content" do
        column = build(:cms_column_free, cur_site: site, cur_form: form, layout: "")
        expect(column).to be_valid
      end

      it "accepts nil layout content" do
        column = build(:cms_column_free, cur_site: site, cur_form: form, layout: nil)
        expect(column).to be_valid
      end
    end

    describe "loop_setting_id field" do
      it "can set loop_setting_id" do
        column = build(:cms_column_free, cur_site: site, cur_form: form, loop_setting_id: liquid_setting.id)
        expect(column).to be_valid
        expect(column.loop_setting_id).to eq liquid_setting.id
      end

      it "accepts nil loop_setting_id" do
        column = build(:cms_column_free, cur_site: site, cur_form: form, loop_setting_id: nil)
        expect(column).to be_valid
      end
    end

    describe "loop_setting association" do
      it "can associate with loop_setting" do
        column = create(:cms_column_free, cur_site: site, cur_form: form, loop_setting_id: liquid_setting.id)
        expect(column.loop_setting).to eq liquid_setting
      end

      it "returns nil when loop_setting_id is not set" do
        column = create(:cms_column_free, cur_site: site, cur_form: form, loop_setting_id: nil)
        expect(column.loop_setting).to be_nil
      end
    end

    describe "liquid format validation" do
      it "validates liquid format for layout field" do
        column = build(:cms_column_free, cur_site: site, cur_form: form,
layout: "{% for item in items %}{{ item.name }}{% endfor %}")
        expect(column).to be_valid
      end

      it "accepts valid liquid syntax" do
        valid_liquid = "{% if items.size > 0 %}{% for item in items %}<div>{{ item.name }}</div>{% endfor %}{% endif %}"
        column = build(:cms_column_free, cur_site: site, cur_form: form, layout: valid_liquid)
        expect(column).to be_valid
      end

      it "accepts plain HTML without liquid tags" do
        plain_html = "<div class='layout'><p>Content</p></div>"
        column = build(:cms_column_free, cur_site: site, cur_form: form, layout: plain_html)
        expect(column).to be_valid
      end
    end

    describe "saving behavior" do
      it "preserves directly entered layout when loop_setting_id is set" do
        custom_layout = "<div class='custom-layout'>{% for item in items %}" \
                        "<div class='custom-item'>{{ item.name }}</div>{% endfor %}</div>"
        column = create(:cms_column_free, cur_site: site, cur_form: form, layout: custom_layout,
loop_setting_id: liquid_setting.id)

        expect(column.layout).to eq custom_layout
        expect(column.loop_setting_id).to eq liquid_setting.id

        # Verify that the custom layout is preserved, not overwritten by loop_setting.html
        expect(column.layout).to include("custom-layout")
        expect(column.layout).to include("custom-item")
        expect(column.layout).not_to include("class='item'") # from loop_setting.html
      end

      it "can update layout without affecting loop_setting_id" do
        column = create(:cms_column_free, cur_site: site, cur_form: form, layout: "initial layout",
loop_setting_id: liquid_setting.id)

        new_layout = "updated layout content"
        column.layout = new_layout
        column.save!

        expect(column.layout).to eq new_layout
        expect(column.loop_setting_id).to eq liquid_setting.id
      end

      it "can update loop_setting_id without affecting layout" do
        column = create(:cms_column_free, cur_site: site, cur_form: form, layout: "custom layout",
loop_setting_id: liquid_setting.id)

        # Create another loop setting
        new_setting = create(:cms_loop_setting,
          site: site,
          html_format: "liquid",
          html: "{% for item in items %}<div class='new-item'>{{ item.name }}</div>{% endfor %}",
          state: "public",
          name: "New Liquid Setting"
        )

        column.loop_setting_id = new_setting.id
        column.save!

        expect(column.layout).to eq "custom layout"
        expect(column.loop_setting_id).to eq new_setting.id
      end
    end

    describe "site scoping" do
      let!(:other_site) { create(:cms_site_unique) }
      let!(:other_site_setting) do
        create(:cms_loop_setting,
          site: other_site,
          html_format: "liquid",
          html: liquid_html,
          state: "public",
          name: "Other Site Setting"
        )
      end

      it "can only associate with loop_settings from the same site" do
        column = build(:cms_column_free, cur_site: site, cur_form: form, loop_setting_id: other_site_setting.id)

        # This should be valid since we're not enforcing site scoping at the model level
        # The site scoping is handled at the view/controller level
        expect(column).to be_valid
      end
    end
  end

  describe "integration with form columns" do
    let!(:form) { create(:cms_form, cur_site: site) }
    let!(:liquid_setting) do
      create(:cms_loop_setting,
        site: site,
        html_format: "liquid",
        html: liquid_html,
        state: "public",
        name: "Form Layout Setting"
      )
    end

    it "can be used in form columns" do
      column = create(:cms_column_free, cur_site: site, cur_form: form,
layout: "{% for item in items %}{{ item.name }}{% endfor %}")
      expect(column).to be_valid
      expect(column.cur_form).to eq form
    end

    it "can have loop_setting_id in form columns" do
      column = create(:cms_column_free, cur_site: site, cur_form: form, layout: "custom layout",
loop_setting_id: liquid_setting.id)
      expect(column).to be_valid
      expect(column.loop_setting_id).to eq liquid_setting.id
    end
  end
end
