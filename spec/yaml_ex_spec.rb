# frozen_string_literal: true

RSpec.describe YamlEx do
  let(:main_content) do
    %(
person:
  name: Kaiser Sakhi
  languages:
    - %[languages]
  %{projects}
  %<personal_details>
    )
  end
  let(:languages_partial) do
    %(
- Java
- Ruby
- JavaScript
    )
  end
  let(:projects) do
    %(
projects:
  health_care_system: "Health care system."
  learning_management_system: "Learning Management System."
    )
  end
  let(:personal_details) do
    %(
address: "Planet Earth"
phone_no: 79834736
is_cool: true
    )
  end
  let(:expected_yaml) do
    {
      "person" => {
        "name" => "Kaiser Sakhi",
        "languages" => %w[Java Ruby JavaScript],
        "projects" => {
          "health_care_system" => "Health care system.",
          "learning_management_system" => "Learning Management System."
        },
        "address" => "Planet Earth",
        "phone_no" => 79834736,
        "is_cool" => true
      }
    }
  end
  let(:yaml_ex) { YamlEx::Parser.new(main_content) }

  it "has a version number" do
    expect(YamlEx::VERSION).not_to be nil
  end

  it "should review and add all the partial" do
    expect(yaml_ex.add_partial(partial: languages_partial, key: "languages")).to_not eq(nil)
    expect(yaml_ex.add_partial(partial: projects, key: "projects")).to_not eq(nil)
    expect(yaml_ex.add_partial(partial: personal_details, key: "personal_details")).to_not eq(nil)

    expect(yaml_ex.parse).to eq(expected_yaml)
  end

  it "should include all the partials in one yaml document" do

  end
end
