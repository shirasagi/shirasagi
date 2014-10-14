module Event::Agents::Addons::Date
  class EditController < ApplicationController
    include SS::AddonFilter::Edit

    javascript "event/form"
  end
end
