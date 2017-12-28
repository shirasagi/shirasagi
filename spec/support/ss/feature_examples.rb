# for features
shared_examples "crud flow" do
  it '#crud' do
    visit index_path

    # new/create
    click_link I18n.t('ss.links.new')
    within 'form#item-form' do
      click_button I18n.t('ss.buttons.save')
    end

    # show
    click_link I18n.t('ss.links.back_to_index')
    #click_link item.name
    visit "#{index_path}/#{item.id}"

    # edit/update
    click_link I18n.t('ss.links.edit')
    within 'form#item-form' do
      click_button I18n.t('ss.buttons.save')
    end

    # delete/destroy
    click_link I18n.t('ss.links.delete')
    within 'form' do
      click_button I18n.t('ss.buttons.delete')
    end

    expect(current_path).to eq index_path
  end
end
