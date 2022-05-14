# frozen_string_literal: true

require 'yard'
require 'yard/to_mkdocs/version'

module YARD
  module Serializers
    class FileSystemSerializer < Base
      def initialize(opts = {})
        super
        @name_map = nil
        @basepath = (options[:basepath] || 'doc').to_s
        @extension = 'md'
      end
    end
  end
end

YARD::Templates::Engine.register_template_path File.expand_path('./yard/to_mkdocs', __dir__)
