module Kana
  class Initializer
    Cms::Role.permission :read_kana_dictionaries
    Cms::Role.permission :edit_kana_dictionaries
    Cms::Role.permission :delete_kana_dictionaries
    Cms::Role.permission :build_kana_dictionaries
  end
end
