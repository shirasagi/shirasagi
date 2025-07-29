class Gws::Tabular::Initializer
  Gws::Role.permission :use_gws_tabular, module_name: 'gws/tabular'

  Gws::Role.permission :read_other_gws_tabular_spaces, module_name: 'gws/tabular'
  Gws::Role.permission :read_private_gws_tabular_spaces, module_name: 'gws/tabular'
  Gws::Role.permission :edit_other_gws_tabular_spaces, module_name: 'gws/tabular'
  Gws::Role.permission :edit_private_gws_tabular_spaces, module_name: 'gws/tabular'
  Gws::Role.permission :delete_other_gws_tabular_spaces, module_name: 'gws/tabular'
  Gws::Role.permission :delete_private_gws_tabular_spaces, module_name: 'gws/tabular'

  Gws::Role.permission :read_other_gws_tabular_forms, module_name: 'gws/tabular'
  Gws::Role.permission :read_private_gws_tabular_forms, module_name: 'gws/tabular'
  Gws::Role.permission :edit_other_gws_tabular_forms, module_name: 'gws/tabular'
  Gws::Role.permission :edit_private_gws_tabular_forms, module_name: 'gws/tabular'
  Gws::Role.permission :delete_other_gws_tabular_forms, module_name: 'gws/tabular'
  Gws::Role.permission :delete_private_gws_tabular_forms, module_name: 'gws/tabular'

  Gws::Role.permission :read_other_gws_tabular_views, module_name: 'gws/tabular'
  Gws::Role.permission :read_private_gws_tabular_views, module_name: 'gws/tabular'
  Gws::Role.permission :edit_other_gws_tabular_views, module_name: 'gws/tabular'
  Gws::Role.permission :edit_private_gws_tabular_views, module_name: 'gws/tabular'
  Gws::Role.permission :delete_other_gws_tabular_views, module_name: 'gws/tabular'
  Gws::Role.permission :delete_private_gws_tabular_views, module_name: 'gws/tabular'

  Gws::Role.permission :read_gws_tabular_files, module_name: 'gws/tabular'
  Gws::Role.permission :edit_gws_tabular_files, module_name: 'gws/tabular'
  Gws::Role.permission :delete_gws_tabular_files, module_name: 'gws/tabular'
  Gws::Role.permission :download_gws_tabular_files, module_name: 'gws/tabular'
  Gws::Role.permission :import_gws_tabular_files, module_name: 'gws/tabular'

  Gws::Tabular::View.plugin Gws::Tabular::View::List.as_plugin
  Gws::Tabular::View.plugin Gws::Tabular::View::Liquid.as_plugin

  Gws::Tabular::Column.plugin Gws::Tabular::Column::TextField.as_plugin
  Gws::Tabular::Column.plugin Gws::Tabular::Column::DateTimeField.as_plugin
  Gws::Tabular::Column.plugin Gws::Tabular::Column::NumberField.as_plugin
  Gws::Tabular::Column.plugin Gws::Tabular::Column::FileUploadField.as_plugin
  Gws::Tabular::Column.plugin Gws::Tabular::Column::EnumField.as_plugin
  Gws::Tabular::Column.plugin Gws::Tabular::Column::ReferenceField.as_plugin
  Gws::Tabular::Column.plugin Gws::Tabular::Column::LookupField.as_plugin

  Gws.module_usable :tabular do |site, user|
    Gws::Tabular.allowed?(:use, user, site: site)
  end

  # アプリケーションサーバーが、メモリ使用量の超過や処理したリクエスト数の超過などにより
  # リサイクルされた - つまり Gws::Tabular::FileXXXXXXXX クラスのキャッシュが破棄された - 状況を考える。
  # このような状況下で、参照 SS::File#owner_item を辿っても Gws::Tabular::FileXXXXXXXX クラスが
  # 見つからないので、参照を辿れない。
  # 参照が辿れないのでファイルへアクセスすることができないと判定される。
  # これでは困るので、起動時に全 Gws::Tabular::FileXXXXXXXX クラスをロードするようにする。
  Gws::Tabular::Form.all.tap do |criteria|
    all_ids = criteria.pluck(:id)
    all_ids.each_slice(20) do |ids|
      criteria.in(id: ids).to_a.each do |form|
        release = form.current_release
        next unless release

        Gws::Tabular::File[release]
      rescue => e
        Rails.logger.warn { "#{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}" }
      end
    end
  end
end
