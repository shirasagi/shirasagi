require 'spec_helper'

describe 'chorg_results', dbscope: :example do
  let!(:site) { cms_site }
  let!(:revision) { create(:revision, site_id: site.id) }
  let!(:changeset) { create(:add_changeset, revision_id: revision.id) }
  let(:show_path) { chorg_result_path site.id, revision.id, type }

  before { login_cms_user }

  context 'test' do
    let(:type) { 'test' }

    describe '#show' do
      context 'no items' do
        it do
          visit show_path
          expect(status_code).to eq 200
          expect(current_path).to eq show_path
          expect(page).to have_selector('dd.started', text: '')
          expect(page).to have_selector('dd.closed', text: '')
        end
      end

      context 'with item' do
        let(:now) { Time.zone.now }

        before do
          Timecop.freeze(now) do
            visit chorg_run_confirmation_path(site.id, revision.id, type)

            perform_enqueued_jobs do
              within 'form#item-form' do
                click_button I18n.t("chorg.views.run/confirmation.#{type}.run_button")
              end
            end
          end
        end

        it do
          visit show_path
          expect(status_code).to eq 200
          expect(current_path).to eq show_path
          expect(page).to have_selector('dd.started', text: now.strftime('%Y/%m/%d %H:%M:%S'))
          expect(page).to have_selector('dd.closed', text: now.strftime('%Y/%m/%d %H:%M:%S'))
          expect(page).to have_selector('dl.mod-chorg-entity_log')
        end
      end
    end
  end

  context 'main' do
    let(:type) { 'main' }

    describe '#show' do
      context 'no items' do
        it do
          visit show_path
          expect(status_code).to eq 200
          expect(current_path).to eq show_path
          expect(page).to have_selector('dd.started', text: '')
          expect(page).to have_selector('dd.closed', text: '')
        end
      end

      context 'with item' do
        let(:now) { Time.zone.now }

        before do
          Timecop.freeze(now) do
            visit chorg_run_confirmation_path(site.id, revision.id, type)

            perform_enqueued_jobs do
              within 'form#item-form' do
                click_button I18n.t("chorg.views.run/confirmation.#{type}.run_button")
              end
            end
          end
        end

        it do
          visit show_path
          expect(status_code).to eq 200
          expect(current_path).to eq show_path
          expect(page).to have_selector('dd.started', text: now.strftime('%Y/%m/%d %H:%M:%S'))
          expect(page).to have_selector('dd.closed', text: now.strftime('%Y/%m/%d %H:%M:%S'))
          expect(page).to have_selector('dl.mod-chorg-entity_log')
        end
      end
    end
  end
end
