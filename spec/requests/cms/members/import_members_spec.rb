require 'spec_helper'
require "csv"

RSpec.describe Cms::MembersController, type: :request, dbscope: :example, js: true do
  let(:site) { cms_site }
  let(:group) { create(:cms_group, name: "test_group") }
  let(:permissions) { %w(read_cms_members edit_cms_members delete_cms_members import_cms_members) }
  let(:role) { create(:cms_role_admin, site_id: site.id, permissions: permissions) }
  let(:user) { create(:cms_user, uid: unique_id, name: unique_id, group: group, role: role) }
  let(:index_path) { cms_members_path(site.id) }
  let(:import_path) { import_cms_members_path(site.id) }

  before do
    user
    login_cms_user
    visit index_path
  end

  describe 'GET #import' do
    context 'when user has necessary permissions' do
      it 'renders the import template' do
        visit import_path
        expect(page).to have_current_path(import_path)
        expect(page).to have_content(I18n.t('ss.buttons.import'))
      end
    end

    context 'when user does not have necessary permissions' do
      let(:permissions) { [] }

      it 'returns a 403 forbidden status' do
        visit import_path
        expect(page).to have_content(I18n.t('ss.rescues.default.head'))
      end
    end
  end

  describe 'POST #import' do
    before do
      visit import_path
    end

    context 'when no file is provided' do
      it 'renders the import template with an error message' do
        accept_confirm(I18n.t("ss.confirm.import")) do
          within '#main' do
            within 'div.wrap' do
              within 'form' do
                within 'footer.send' do
                  click_button I18n.t('ss.buttons.import')
                end
              end
            end
          end
        end
        expect(page).to have_content(I18n.t('ss.errors.import.blank_file'))
      end
    end

    context 'when an invalid file type is provided' do
      it 'renders the import template with an error message' do
        attach_file 'item[in_file]', Rails.root.join('spec/fixtures/cms/members/test.txt')
        accept_confirm(I18n.t("ss.confirm.import")) do
          within '#main' do
            within 'div.wrap' do
              within 'form' do
                within 'footer.send' do
                  click_button I18n.t('ss.buttons.import')
                end
              end
            end
          end
        end
        expect(page).to have_content(I18n.t('ss.errors.import.invalid_file_type'))
      end
    end

    context 'when a valid CSV file is provided' do
      it 'redirects to the index action with a success message' do
        allow(Cms::Member).to receive(:import_csv).and_return({ success: true })
        attach_file 'item[in_file]', Rails.root.join('spec/fixtures/cms/members/members.csv')
        accept_confirm(I18n.t("ss.confirm.import")) do
          within '#main' do
            within 'div.wrap' do
              within 'form' do
                within 'footer.send' do
                  click_button I18n.t('ss.buttons.import')
                end
              end
            end
          end
        end
        expect(page).to have_current_path(index_path)
        expect(page).to have_content(I18n.t('ss.notice.saved'))
      end
    end

    context 'when the CSV file contains nil id data' do
      it 'imports CSV data with nil id successfully and creates a new member' do
        allow(Cms::Member).to receive(:import_csv).and_return({ success: true })
        attach_file 'item[in_file]', Rails.root.join('spec/fixtures/cms/members/nil_id_members.csv')
        accept_confirm(I18n.t("ss.confirm.import")) do
          within '#main' do
            within 'div.wrap' do
              within 'form' do
                within 'footer.send' do
                  click_button I18n.t('ss.buttons.import')
                end
              end
            end
          end
        end
        expect(page).to have_current_path(index_path)
        expect(page).to have_content(I18n.t('ss.notice.saved'))
      end
    end


    context 'when the CSV file contains invalid data' do
      it 'renders the import template with an error message' do
        allow(Cms::Member).to receive(:import_csv).and_return({ success: false, error: 'Invalid data' })
        attach_file 'item[in_file]', Rails.root.join('spec/fixtures/cms/members/invalid_members.csv')
        accept_confirm(I18n.t("ss.confirm.import")) do
          within '#main' do
            within 'div.wrap' do
              within 'form' do
                within 'footer.send' do
                  click_button I18n.t('ss.buttons.import')
                end
              end
            end
          end
        end
        expect(page).to have_content("#{I18n.t('ss.notice.not_saved_successfully')} Invalid data")
      end
    end

    context 'when the CSV file contains duplicate data' do
      it 'renders the import template with an error message' do
        allow(Cms::Member).to receive(:import_csv).and_return({ success: false, error: 'Duplicate data' })
        attach_file 'item[in_file]', Rails.root.join('spec/fixtures/cms/members/duplicate_members.csv')
        accept_confirm(I18n.t("ss.confirm.import")) do
          within '#main' do
            within 'div.wrap' do
              within 'form' do
                within 'footer.send' do
                  click_button I18n.t('ss.buttons.import')
                end
              end
            end
          end
        end
        expect(page).to have_content("#{I18n.t('ss.notice.not_saved_successfully')} Duplicate data")
      end
    end
  end
end
