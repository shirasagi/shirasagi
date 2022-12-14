class Gws::Workflow::WizardController < ApplicationController
  include Gws::ApiFilter
  include Gws::Workflow::WizardFilter

  def set_model
    @model = Gws::Workflow::File
  end
end
