class Sys::Auth::Base
  include Sys::Model::Auth

  READY_STATE_EXPIRES_IN = 10.minutes.to_i
end
