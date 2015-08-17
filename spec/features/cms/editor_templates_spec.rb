require 'spec_helper'

describe "cms_editor_templates", dbscope: :example, type: :feature do
  let(:site) { cms_site }
  let(:item) { create(:cms_editor_template, site: site) }
  let(:index_path) { cms_editor_templates_path site.id }
  let(:new_path) { new_cms_editor_template_path site.id }
  let(:show_path) { cms_editor_template_path site.id, item }
  let(:edit_path) { edit_cms_editor_template_path site.id, item }
  let(:delete_path) { delete_cms_editor_template_path site.id, item }
  let(:thumb_path) { Rails.root.join("spec", "fixtures", "ss", "logo.png").to_s }
  let(:template_path) { template_cms_editor_templates_path site.id }

  it "without login" do
    visit index_path
    expect(current_path).to eq sns_login_path
  end

  it "without auth" do
    login_ss_user
    visit index_path
    expect(status_code).to eq 403
  end

  context "with auth" do
    before { login_cms_user }

    describe "#index" do
      it do
        visit index_path
        expect(status_code).to eq 200
        expect(current_path).to eq index_path
      end
    end

    describe "#new" do
      it do
        visit new_path
        within "form#item-form" do
          fill_in "item[name]", with: "name-#{unique_id}"
          fill_in "item[description]", with: "description-#{unique_id}"
          fill_in "item[html]", with: "html-#{unique_id}"
          attach_file "item[in_thumb]", thumb_path
          click_button "保存"
        end
        expect(status_code).to eq 200
        expect(current_path).not_to eq new_path
        expect(page).not_to have_css("form#item-form")
      end
    end

    describe "#show" do
      it do
        visit show_path
        expect(status_code).to eq 200
        expect(current_path).to eq show_path
      end
    end

    describe "#edit" do
      it do
        visit edit_path
        within "form#item-form" do
          fill_in "item[name]", with: "name-#{unique_id}"
          fill_in "item[description]", with: "description-#{unique_id}"
          fill_in "item[html]", with: "html-#{unique_id}"
          attach_file "item[in_thumb]", thumb_path
          click_button "保存"
        end
        expect(status_code).to eq 200
        expect(current_path).not_to eq sns_login_path
        expect(page).not_to have_css("form#item-form")
      end
    end

    describe "#delete" do
      it do
        visit delete_path
        within "form" do
          click_button "削除"
        end
        expect(status_code).to eq 200
        expect(current_path).to eq index_path
      end
    end

    describe "#template" do
      context "when editor is ckeditor" do
        before do
          @save = SS.config.cms.html_editor
          SS.config.replace_value_at(:cms, :html_editor, "ckeditor")
        end

        after do
          SS.config.replace_value_at(:cms, :html_editor, @save)
        end

        context "when js is requested" do
          before { item.reload }
          it do
            visit "#{template_path}.js"
            expect(status_code).to eq 200

            expect(page.source).to start_with("CKEDITOR.addTemplates( 'shirasagi',")
            expect(page.source).to end_with("} );\n\n")
            expect(page.source).to include("\"title\":\"#{item.name}\"")
            expect(page.source).to include("\"description\":\"#{item.description}\"")
            expect(page.source).to include("\"html\":\"#{item.html}\"")
          end
        end

        context "when json is requested" do
          before { item.reload }
          it do
            visit "#{template_path}.json"
            expect(status_code).to eq 200

            source = JSON.parse(page.source)
            expect(source).to be_empty
          end
        end
      end

      context "when editor is tinymce" do
        before do
          @save = SS.config.cms.html_editor
          SS.config.replace_value_at(:cms, :html_editor, "tinymce")
        end

        after do
          SS.config.replace_value_at(:cms, :html_editor, @save)
        end

        context "when js is requested" do
          before { item.reload }
          it do
            visit "#{template_path}.js"
            expect(status_code).to eq 200

            expect(page.source).to be_empty
          end
        end

        context "when json is requested" do
          before { item.reload }
          it do
            visit "#{template_path}.json"
            expect(status_code).to eq 200

            source = JSON.parse(page.source)
            expect(source).to include(include("title" => item.name, "description" => item.description, "content" => item.html))
          end
        end
      end
    end
  end
end
