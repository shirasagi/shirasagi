# for features
shared_examples "crud flow" do
  it '#crud' do
    visit index_path

    # new/create
    click_link I18n.t('ss.links.new')
    click_button I18n.t('ss.buttons.save')

    # show
    click_link I18n.t('ss.links.back_to_index')
    #click_link item.name
    visit "#{index_path}/#{item.id}"

    # edit/update
    click_link I18n.t('ss.links.edit')
    click_button I18n.t('ss.buttons.save')

    # delete/destroy
    click_link I18n.t('ss.links.delete')
    click_button I18n.t('ss.buttons.delete')

    expect(status_code).to eq 200
    expect(current_path).to eq index_path
  end
end
