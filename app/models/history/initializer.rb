module History
  class Initializer
    ::Cms::Role.permission :read_history_trashes
    ::Cms::Role.permission :edit_history_trashes
    ::Cms::Role.permission :delete_history_trashes
  end
end
