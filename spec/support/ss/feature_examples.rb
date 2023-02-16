# for features
shared_examples "crud flow" do
  let!(:inputs) { [] }

  it '#crud' do
    visit index_path

    # new/create
    click_link I18n.t('ss.links.new')
    within 'form#item-form' do
      inputs.each { |n| fill_in "item[#{n}]", with: unique_id }
      click_button I18n.t('ss.buttons.save')
    end
    expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved')) if inputs.present?

    # show
    click_link I18n.t('ss.links.back_to_index')
    #click_link item.name
    visit "#{index_path}/#{item.id}"

    # edit/update
    click_link I18n.t('ss.links.edit')
    within 'form#item-form' do
      inputs.each { |n| fill_in "item[#{n}]", with: unique_id }
      click_button I18n.t('ss.buttons.save')
    end
    expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved')) if inputs.present?

    # delete/destroy
    click_link I18n.t('ss.links.delete')
    within 'form' do
      click_button I18n.t('ss.buttons.delete')
    end

    expect(current_path).to eq index_path
  end
end
