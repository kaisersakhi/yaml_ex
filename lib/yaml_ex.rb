require_relative "yaml_ex/version"
require "psych"

module YamlEx
  class YamlExParserError < StandardError

  end

  class Parser
    TYPE_MAPPING = :map
    TYPE_SEQUENCE = :sequence
    TYPE_SCALAR = :scalar

    def initialize(content)
      @main = content
      @partials = []
    end

    def add_partial(partial:, key:)
      type = partial_type(partial)

      if type == :unknown
        raise YamlExParserError, (partial << "\n" << "Couldn't determine the type of the above partial.")
      end

      @partials << { key => {
        text: partial,
        type: type
      } }
    end

    def whole_yaml
      process
    end

    def parse
      Psych.load(process)
    end

    private

    def process
      return main if partials.empty?

      whole_doc = ""
      all_partials = partials.reduce({}, :merge)
      main.each_line&.with_index do |line, line_no|
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

    def check_for_errors(key, all_partials, type, line_no)
      return unless key && all_partials[key][:type] != type

        # TODO: elaborate error here
      raise YamlExParserError,
            ("Error in main:doc at line no: #{line_no}\n" << "Type specified in the main:doc doesn't match with the type of corresponding partial." << "\n" << line)

    end

    def key_scount_type(line)
      case line
      when /\s*-\s*%\[(.*?)\]/
        [::Regexp.last_match(1), line.match(/^\s*/)[0].length, TYPE_SEQUENCE]
      when /\s*%{(.*?)}\s*\n/
        [::Regexp.last_match(1), line.match(/^\s*/)[0].length, TYPE_MAPPING]
      when /\s*%<(.*?)>/
        [::Regexp.last_match(1), line.match(/^\s*/)[0].length, TYPE_SCALAR]
      else
        []
      end
    end

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

    def process_partial(partial, scount)
      processed_partial = ""
      partial&.each_line do |line|
        processed_partial << ((" " * scount) << line)
      end
      processed_partial
    end

    attr_reader :main, :partials
  end
end
