require 'spec_helper'

describe Cms::Column::Base, type: :model, dbscope: :example do
  let!(:site) { cms_site }
  let!(:form) { create(:cms_form, cur_site: site) }

  describe "layout functionality" do
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

    describe "loop_setting association" do
      let!(:loop_setting) { create(:cms_loop_setting, site: site) }

      it "is optional" do
        column = build(:cms_column_free, cur_site: site, cur_form: form, loop_setting: nil)
        expect(column).to be_valid
      end

      it "accepts assigned loop_setting" do
        column = build(:cms_column_free, cur_site: site, cur_form: form, loop_setting: loop_setting)
        expect(column).to be_valid
        expect(column.loop_setting).to eq loop_setting
      end
    end
  end

  describe "integration with form columns" do
    let!(:form) { create(:cms_form, cur_site: site) }

    it "can be used in form columns" do
      column = create(:cms_column_free, cur_site: site, cur_form: form,
layout: "{% for item in items %}{{ item.name }}{% endfor %}")
      expect(column).to be_valid
      expect(column.cur_form).to eq form
    end
  end
end
