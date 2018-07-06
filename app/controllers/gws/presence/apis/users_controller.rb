class Gws::Presence::Apis::UsersController < ApplicationController
  include Gws::ApiFilter
  include Gws::BaseFilter
  include Gws::Presence::Users::ApiFilter
end
