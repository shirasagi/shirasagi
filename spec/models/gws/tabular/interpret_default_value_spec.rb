require 'spec_helper'

describe Gws::Tabular, type: :model, dbscope: :example do
  let!(:site) do
    Gws::Group.create!(name: "name-#{unique_id}", order: 10)
  end

  describe ".interpret_default_value" do
    let!(:group) do
      Gws::Group.create!(name: "#{site.name}/name-#{unique_id}", order: 20)
    end
    let!(:user) do
      create(
        :gws_user, kana: unique_id, tel: unique_tel, tel_ext: unique_tel,
        organization_id: site.id, organization_uid: unique_id, group_ids: [ group.id ])
    end

    before do
      SS.current_user = user
      SS.current_user_group = group
    end

    after do
      SS.current_user = nil
      SS.current_user_group = nil
    end

    context '{{ user.name }}' do
      it do
        value = Gws::Tabular.interpret_default_value("{{ user.name }}")
        expect(value).to eq user.name
      end
    end

    context '{{ user.kana }}' do
      it do
        value = Gws::Tabular.interpret_default_value("{{ user.kana }}")
        expect(value).to eq user.kana
      end
    end

    context '{{ user.uid }}' do
      it do
        value = Gws::Tabular.interpret_default_value("{{ user.uid }}")
        expect(value).to eq user.uid
      end
    end

    context '{{ user.email }}' do
      it do
        value = Gws::Tabular.interpret_default_value("{{ user.email }}")
        expect(value).to eq user.email
      end
    end

    context '{{ user.tel }}' do
      it do
        value = Gws::Tabular.interpret_default_value("{{ user.tel }}")
        expect(value).to eq user.tel
      end
    end

    context '{{ user.tel_ext }}' do
      it do
        value = Gws::Tabular.interpret_default_value("{{ user.tel_ext }}")
        expect(value).to eq user.tel_ext
      end
    end

    context '{{ user.organization_uid }}' do
      it do
        value = Gws::Tabular.interpret_default_value("{{ user.organization_uid }}")
        expect(value).to eq user.organization_uid
      end
    end

    context '{{ user.lang }}' do
      it do
        value = Gws::Tabular.interpret_default_value("{{ user.lang }}")
        expect(value).to eq user.lang
      end
    end

    context '{{ group.name }}' do
      it do
        value = Gws::Tabular.interpret_default_value("{{ group.name }}")
        expect(value).to eq group.name
      end
    end

    context '{{ group.full_name }}' do
      it do
        value = Gws::Tabular.interpret_default_value("{{ group.full_name }}")
        expect(value).to eq group.full_name
      end
    end

    context '{{ group.section_name }}' do
      it do
        value = Gws::Tabular.interpret_default_value("{{ group.section_name }}")
        expect(value).to eq group.section_name
      end
    end

    context '{{ group.trailing_name }}' do
      it do
        value = Gws::Tabular.interpret_default_value("{{ group.trailing_name }}")
        expect(value).to eq group.trailing_name
      end
    end
  end
end
