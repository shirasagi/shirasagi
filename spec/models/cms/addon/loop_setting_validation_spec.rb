require 'spec_helper'

RSpec.shared_examples 'loop setting reference validation' do
  let!(:other_site) { create(:cms_site_unique) }
  let!(:valid_setting) do
    create(:cms_loop_setting, :liquid, :template_type, cur_site: site)
  end
  let!(:other_site_setting) do
    create(:cms_loop_setting, :liquid, :template_type, cur_site: other_site)
  end
  let!(:snippet_setting) do
    create(:cms_loop_setting, :liquid, :snippet_type, cur_site: site)
  end
  let!(:shirasagi_setting) do
    create(:cms_loop_setting, :shirasagi, :template_type, cur_site: site)
  end

  it 'rejects a loop setting from another site' do
    item.loop_setting_id = other_site_setting.id

    expect(item).not_to be_valid
    expect(item.errors[:loop_setting_id]).to be_present
  end

  it 'rejects a snippet setting' do
    item.loop_setting_id = snippet_setting.id

    expect(item).not_to be_valid
    expect(item.errors[:loop_setting_id]).to be_present
  end

  it 'rejects a loop setting whose format does not match' do
    item.loop_setting_id = shirasagi_setting.id

    expect(item).not_to be_valid
    expect(item.errors[:loop_setting_id]).to be_present
  end

  it 'accepts a template setting with the same site and format' do
    item.reload
    item.loop_setting_id = valid_setting.id

    expect(item).to be_valid
    expect(item.errors[:loop_setting_id]).to be_blank
  end

  it 'does not validate an unchanged invalid loop setting reference' do
    item.set(loop_setting_id: snippet_setting.id)
    item.reload
    item.name = "updated-#{unique_id}"

    expect(item.save).to be true
    expect(item.errors[:loop_setting_id]).to be_blank
  end
end

describe Cms::Addon::LoopSettingValidation, type: :model, dbscope: :example do
  let!(:site) { cms_site }

  context 'with Cms::Addon::List' do
    let!(:item) { create(:article_node_page, cur_site: site, loop_format: 'liquid') }

    it_behaves_like 'loop setting reference validation'

    it 'accepts a shirasagi setting when loop_format is shirasagi' do
      setting = create(:cms_loop_setting, :shirasagi, :template_type, cur_site: site)
      item.loop_format = 'shirasagi'
      item.loop_setting_id = setting.id

      expect(item).to be_valid
      expect(item.errors[:loop_setting_id]).to be_blank
    end

    it 'rejects changing only loop_format to shirasagi with a liquid setting' do
      setting = create(:cms_loop_setting, :liquid, :template_type, cur_site: site)
      item.update!(loop_setting_id: setting.id)

      item.loop_format = 'shirasagi'

      expect(item.save).to be false
      expect(item.errors[:loop_setting_id]).to be_present
    end

    it 'rejects changing only loop_format to liquid with a shirasagi setting' do
      setting = create(:cms_loop_setting, :shirasagi, :template_type, cur_site: site)
      item.update!(loop_format: 'shirasagi', loop_setting_id: setting.id)

      item.loop_format = 'liquid'

      expect(item.save).to be false
      expect(item.errors[:loop_setting_id]).to be_present
    end
  end

  context 'with Cms::Addon::LayoutHtml' do
    let!(:item) { create(:cms_form, cur_site: site) }

    it_behaves_like 'loop setting reference validation'
  end

  context 'with Cms::Addon::Column::Layout' do
    let!(:form) { create(:cms_form, cur_site: site) }
    let!(:item) { create(:cms_column_free, cur_site: site, cur_form: form) }

    it_behaves_like 'loop setting reference validation'
  end
end
