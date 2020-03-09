require 'spec_helper'

describe "cms_editor_templates", type: :feature, dbscope: :example do
  let(:site) { cms_site }
  let(:index_path) { cms_editor_templates_path site.id }
  let(:thumb_path) { Rails.root.join("spec", "fixtures", "ss", "logo.png").to_s }
  let(:template_path) { template_cms_editor_templates_path site.id }
  let!(:file) { tmp_ss_file(user: cms_user, site: site, contents: thumb_path) }

  context "basic crud", js: true do
    let(:name) { "name-#{unique_id}" }
    let(:description) { "description-#{unique_id}" }
    let(:html) { "html-#{unique_id}" }
    let(:name2) { "name-#{unique_id}" }
    let(:description2) { "description-#{unique_id}" }
    let(:html2) { "html-#{unique_id}" }

    before { login_cms_user }

    it do
      #
      # Create
      #
      visit index_path
      click_on I18n.t("ss.links.new")
      within "form#item-form" do
        fill_in "item[name]", with: name
        fill_in "item[description]", with: description
        fill_in_code_mirror "item[html]", with: html
        first(".btn-file-upload").click
      end
      wait_for_cbox do
        click_on file.name
      end
      within "form#item-form" do
        click_button I18n.t('ss.buttons.save')
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))

      expect(Cms::EditorTemplate.all.count).to eq 1
      item = Cms::EditorTemplate.all.first
      expect(item.name).to eq name
      expect(item.description).to eq description
      expect(item.html).to eq html
      expect(item.thumb).to be_present

      #
      # Update
      #
      visit index_path
      click_on item.name
      click_on I18n.t("ss.links.edit")

      within "form#item-form" do
        fill_in "item[name]", with: name2
        fill_in "item[description]", with: description2
        fill_in_code_mirror "item[html]", with: html2
        click_button I18n.t('ss.buttons.save')
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))

      item.reload
      expect(item.name).to eq name2
      expect(item.description).to eq description2
      expect(item.html).to eq html2
      expect(item.thumb).to be_present

      visit index_path
      click_on item.name
      click_on I18n.t("ss.links.delete")

      within "form" do
        click_button I18n.t('ss.buttons.delete')
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.deleted'))
    end
  end

  describe "#template" do
    let!(:item) { create(:cms_editor_template, site: site) }

    before { login_cms_user }

    context "when editor is ckeditor" do
      before do
        @save = SS.config.cms.html_editor
        SS.config.replace_value_at(:cms, :html_editor, "ckeditor")
      end

      after do
        SS.config.replace_value_at(:cms, :html_editor, @save)
      end

      context "when js is requested" do
        it do
          visit "#{template_path}.js"

          expect(page.source).to start_with("CKEDITOR.addTemplates( 'shirasagi',")
          expect(page.source).to end_with("} );\n\n")
          expect(page.source).to include("\"title\":\"#{item.name}\"")
          expect(page.source).to include("\"description\":\"#{item.description}\"")
          expect(page.source).to include("\"html\":\"#{item.html}\"")
        end
      end

      context "when json is requested" do
        it do
          visit "#{template_path}.json"

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
        it do
          visit "#{template_path}.js"

          expect(page.source).to be_empty
        end
      end

      context "when json is requested" do
        it do
          visit "#{template_path}.json"

          source = JSON.parse(page.source)
          expect(source).to include(include("title" => item.name, "description" => item.description, "content" => item.html))
        end
      end
    end
  end

  context "with normal user (editor template can read all users having edit_page privilege)" do
    let!(:role) do
      Cms::Role.create!(
        name: "role_#{unique_id}",
        permissions: Cms::Role.permission_names.reject { |name| name.include?('cms_users') },
        site_id: site.id
      )
    end
    let!(:user) { create(:cms_test_user, group: cms_group, role: role) }
    let!(:item) { create(:cms_editor_template, site: site) }

    before { login_user user }

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
          it do
            visit "#{template_path}.js"

            expect(page.source).to start_with("CKEDITOR.addTemplates( 'shirasagi',")
            expect(page.source).to end_with("} );\n\n")
            expect(page.source).to include("\"title\":\"#{item.name}\"")
            expect(page.source).to include("\"description\":\"#{item.description}\"")
            expect(page.source).to include("\"html\":\"#{item.html}\"")
          end
        end

        context "when json is requested" do
          it do
            visit "#{template_path}.json"

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
          it do
            visit "#{template_path}.js"
            expect(page.source).to be_empty
          end
        end

        context "when json is requested" do
          it do
            visit "#{template_path}.json"

            source = JSON.parse(page.source)
            expect(source).to include(include("title" => item.name, "description" => item.description, "content" => item.html))
          end
        end
      end
    end
  end
end
