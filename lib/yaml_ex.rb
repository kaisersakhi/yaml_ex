require_relative "yaml_ex/version"
require "psych"

module YamlEx
  class YamlExParserError < StandardError

  end

  # Parses templated yaml with partials.
  class Parser
    TYPE_MAPPING = :map
    TYPE_SEQUENCE = :sequence
    TYPE_SCALAR = :scalar

    def initialize(content)
      self.main = content
      @partials = []
    end

    # Adds partial
    def add_partial(partial:, key:)
      type = partial_type(partial)

      if type == :unknown
        raise YamlExParserError, (partial << "\n" << "Couldn't determine the type of the above partial.")
      end

      @partials << { key => {
        text: format_and_validate(partial),
        type: type
      } }
    end

    # Return full/processed text/yaml
    def whole_yaml
      process
    end

    # Returns the processed/full yaml as a Hash
    def parse
      Psych.load(process)
    end

    # Loads partial text and keys, from partial objects.
    def load_with_objects(content: nil, partials:, partial_method:, partial_key_method:)
      return false if content.nil? && main.nil? || partials.nil? || partials.empty?

      self.main = content
      partials.each do |partial_object|
        add_partial(partial: partial_object.send(partial_method), key: partial_object.send(partial_key_method))
      end
      true
    end

    # Loads the files in specified dir, and adds them as partials.
    def load_with_files(main_file_name: nil, partials_path:)
      if !main_file_name.nil?
        self.main = File.read(main_file_name)
      elsif main.nil? # Supposes, main content has been supplied with the constructor.
        return false
      end

      partial_files = Dir.entries(partials_path).reject { |file|
        file == "." || file == ".." || !(File.basename(file.downcase).include?("yml") || File.basename(file.downcase).include?("yaml")) || File.basename(file) == File.basename(main_file_name)
      }
      partial_files.each do |file_name|
        base_name = File.basename(file_name)
        key = if base_name.include?("yml")
                base_name.sub(".yml", "")
              else
                base_name.sub(".yaml", "")
              end
        file_contents = File.read(File.join(partials_path, file_name))
        next if file_contents.empty?

        add_partial(partial: file_contents, key: key)
      end
      true
    end

    private

    # Does the main job, goes through the main_content/custom_yaml and replaces templates with partials
    def process
      if partials.empty?
        raise YamlExParserError, "Couldn't evaluate custom yaml without partials."
      elsif main.nil?
        raise YamlExParserError, "Custom YAML must exist before parsing."
      end

      whole_doc = ""
      all_partials = partials.reduce({}, :merge)
      main&.each_line&.with_index do |line, line_no|
        key, scount, type = key_scount_type(line)
        check_for_errors(key, all_partials, type, line_no)
        whole_doc << if key
                       (process_partial(all_partials[key][:text], scount) || "")
                     else
                       line
                     end
      end
      whole_doc
    end

    # Checks if partial type matches the template specified types.
    def check_for_errors(key, all_partials, type, line_no)
      if !key.nil? && all_partials[key].nil?
        raise YamlExParserError, "Partial doesn't exist with key as '#{key}'"
      end

      return unless !key.nil? && all_partials[key][:type] != type

      raise YamlExParserError,
            ("Error in main:doc at line no: #{line_no}\n" << "Type specified in the main:doc doesn't match with the type of corresponding partial." << "\n" << line)
    end

    # Determines partial key, spaces count in-front of a template, type and return as an array [key, space_count, type]
    def key_scount_type(line)
      case line
      when /\s*%\[(.*?)\]/
        [::Regexp.last_match(1), line.match(/^\s*/)[0].length, TYPE_SEQUENCE]
      when /\s*%{(.*?)}\s*\n/
        [::Regexp.last_match(1), line.match(/^\s*/)[0].length, TYPE_MAPPING]
      when /\s*%<(.*?)>/
        [::Regexp.last_match(1), line.match(/^\s*/)[0].length, TYPE_SCALAR]
      else
        []
      end
    end

    # Determines the partial type.
    def partial_type(partial)
      case partial
      when /^\n*\s*-\s*\w+/
        TYPE_SEQUENCE
      when /^\n*\s*\w+\s*:\s*\n/
        TYPE_MAPPING
      when /^\n*\s*\w+\s*:\s+\w+/
        TYPE_SCALAR
      else
        :unknown
      end
    end

    # Inserts spaces in-front of the partial.
    def process_partial(partial, scount)
      processed_partial = ""
      partial&.each_line do |line|
        processed_partial << ((" " * scount) << line)
      end
      processed_partial
    end

    # Parses the partial, and also removes front spaces.
    def format_and_validate(partial)
      parsed_partial = Psych.load(partial)
      Psych.dump(parsed_partial).sub("---\n", "")
    rescue YamlExParserError => e
      e.message
    end

    def main=(content)
      is_main_yaml_correct(content)
      @main = content
    rescue Psych::SyntaxError => e
      @main = nil
      raise YamlExParserError,
            "Could not parse the custom yaml, please check the placement of templates and proper space indentation.\nFollowing are the error that might help: " << e.message
    end

    # Substitutes random data for partials, and parses the custom yaml.
    def is_main_yaml_correct(content)
      mapping_test = <<~MAPPING_TEST
        ______$$$testing_map$$$______:
          ______$$$test$$$______: "Test"
      MAPPING_TEST

      sequence_test = <<~SEQUENCE_TEST
        - ______$$$test_seq$$$______: "Array"
      SEQUENCE_TEST

      scalar_test = <<~SCALAR_TEST
        ______$$$scalar_test_1$$$______: "Scalar 1"
        ______$$$scalar_test_2$$$______: "Scalar 2"
      SCALAR_TEST

      test_partials = {
        "mapping_test" => {
          type: TYPE_MAPPING,
          text: mapping_test
        },
        "sequence_test" => {
          type: TYPE_SEQUENCE,
          text: sequence_test
        },
        "scalar_test" => {
          type: TYPE_SCALAR,
          text: scalar_test
        }
      }

      test_yaml = ""
      content.each_line.with_index do |line, line_no|
        _, scount, type = key_scount_type(line)
        key = case type
              when TYPE_SCALAR
                "scalar_test"
              when TYPE_SEQUENCE
                "sequence_test"
              when TYPE_MAPPING
                "mapping_test"
              else
                nil
              end

        test_yaml << if key
                       (process_partial(test_partials[key][:text], scount) || "")
                     else
                       line
                     end
      end
      Psych.load(test_yaml)
    end

    attr_reader :main, :partials
  end
end
