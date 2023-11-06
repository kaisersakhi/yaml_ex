# frozen_string_literal: true
require_relative 'partial_object'

RSpec.describe YamlEx do
  let(:main_content) do
    <<~MAIN_CONTENT
      person:
        name: Kaiser Sakhi
        languages:
          - C
          %[languages]
          - Kotlin
        %{projects}
        %<personal_details>
    MAIN_CONTENT
  end
  let(:languages_partial) do
    <<~LANGUAGES
      - Java
      - Ruby
      - JavaScript
    LANGUAGES
  end
  let(:projects) do
    <<~PROJECTS
      projects:
        health_care_system: "Health care system."
        learning_management_system: "Learning Management System."
    PROJECTS
  end
  let(:personal_details) do
    <<~PERSONAL_DETAILS
      address: "Planet Earth"
      phone_no: 79834736
      is_cool: true
    PERSONAL_DETAILS
  end
  let(:expected_yaml) do
    {
      "person" => {
        "name" => "Kaiser Sakhi",
        "languages" => %w[C Java Ruby JavaScript Kotlin],
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

  it "should load from file and parse" do
    expect(yaml_ex.load_with_files(main_file_name: (Dir.getwd << "/spec" << "/files/main.yml"), partials_path: (Dir.getwd << "/spec" << "/files"))).to eq(true)
    expect(yaml_ex.whole_yaml).to eq(File.read(Dir.getwd << "/spec/files/expected_data.yml"))
  end

  it "should load from object" do
    partials = []
    Dir.entries("./spec/files").reject { |file|
      file == "." || file == ".." || !(File.basename(file.downcase).include?("yml") || File.basename(file.downcase).include?("yaml")) || File.basename(file) == File.basename("./spec/files/main.yml")
    }.each do |file_name|
      base_name = File.basename(file_name)
      key = if base_name.include?("yml")
              base_name.sub(".yml", "")
            else
              base_name.sub(".yaml", "")
            end
      file_contents = File.read(File.join("./spec/files", file_name))
      next if file_contents.empty?
      partials << PartialObject.new(partial_text: file_contents, key: key)
    end
    expect(yaml_ex.load_with_objects(content: File.read("./spec/files/main.yml"), partials: partials, partial_method: :partial_text, partial_key_method: :key)).to eq(true)
    expect(yaml_ex.whole_yaml).to eq(File.read(Dir.getwd << "/spec/files/expected_data.yml"))
  end
end
