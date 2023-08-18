FactoryBot.define do
  factory :guide_procedure, class: Guide::Procedure do
    name { unique_id }
    id_name { unique_id }
    link_url { "https://shirasagi.example.jp" }
    html { "<p>#{unique_id}</p>" }
    procedure_location { "location1\nlocation2\nlocation3" }
    belongings { "belong1\nbelong2\nbelong3" }
    procedure_applicant { "applicant1\napplicant2\napplicant3" }
    remarks { "remarks" }
  end
end
