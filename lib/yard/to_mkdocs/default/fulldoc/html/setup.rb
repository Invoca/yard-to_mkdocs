# frozen_string_literal: true

require 'yaml'

include Helpers::ModuleHelper

def init
  options.serializer.extension = 'md'

  options.objects = objects = run_verifier(options.objects)

  return serialize_onefile if options.onefile
  options.files.each_with_index do |file, _i|
    serialize_file(file, file.title)
  end

  options.delete(:objects)
  options.delete(:files)

  objects.each do |object|
    begin
      serialize(object)
    rescue => e
      path = options.serializer.serialized_path(object)
      log.error "Exception occurred while generating '#{path}'"
      log.backtrace(e)
    end
  end

  mkdocs_file_path = File.expand_path('../../mkdocs.yml', options.serializer.basepath)
  if File.exists?(mkdocs_file_path)
    mkdocs_yaml = YAML.load_file(mkdocs_file_path)
    mkdocs_nav = mkdocs_yaml['nav'].reject { |item| item["YARD Docs"] }
    mkdocs_yaml['nav'] = mkdocs_nav + [{ options[:title] => mkdocs_nav_tree(objects.first) }]
    File.open(mkdocs_file_path, 'w') { |f| f.write(mkdocs_yaml.to_yaml) }
  end
end

def mkdocs_nav_tree(current_object, current_path = "yard_docs")
  return unless [:root, :class, :module].include?(current_object.type)

  name = current_object.name
  data = if current_object.children.any?
    next_path = current_object.type == :root ? current_path : "#{current_path}/#{name}"
    { name.to_s => ["#{current_path}/#{name}.md", *current_object.children.map { |child| mkdocs_nav_tree(child, next_path) }].compact }
  else
    { name.to_s => "#{current_path}/#{name}.md" }
  end

  if current_object.type == :root
    data['root'][1..-1]
  else
    data
  end
end

# Generate an HTML document for the specified object. This method is used by
# most of the objects found in the Registry.
# @param [CodeObject] object to be saved to HTML
def serialize(object)
  options.object = object
  serialize_index(options) if object == '_index.md' && options.readme.nil?
  Templates::Engine.with_serializer(object, options.serializer) do
    T('layout').run(options)
  end
end

# Generate the documentation output in one file (--one-file) which will load the
# contents of all the javascript and css and output the entire contents without
# depending on any additional files
def serialize_onefile
  Templates::Engine.with_serializer('index.md', options.serializer) do
    T('onefile').run(options)
  end
end

# Generate the index document for the output
# @params [Hash] options contains data and flags that influence the output
def serialize_index(options)
  Templates::Engine.with_serializer('index.md', options.serializer) do
    T('layout').run(options.merge(:index => true))
  end
end

# Generate a single HTML file with the layout template applied. This is generally
# the README file or files specified on the command-line.
#
# @param [File] file object to be saved to the output
# @param [String] title currently unused
#
# @see layout#diskfile
def serialize_file(file, title = nil) # rubocop:disable Lint/UnusedMethodArgument
  options.object = Registry.root
  options.file = file
  # outfile = 'file.' + file.name + '.md'

  serialize_index(options) if file == options.readme
  # Templates::Engine.with_serializer(outfile, options.serializer) do
  #   T('layout').run(options)
  # end
  options.delete(:file)
end

#
# Generates a file to the output with the specified contents.
#
# @example saving a custom html file to the documentation root
#
#   asset('my_custom.md','## Custom File')
#
# @param [String] path relative to the document output where the file will be
#   created.
# @param [String] content the contents that are saved to the file.
def asset(path, content)
  if options.serializer
    log.capture("Generating asset #{path}") do
      options.serializer.serialize(path, content)
    end
  end
end

def menu_lists
  Object.new.extend(T('layout')).menu_lists
end

# Generate a searchable method list in the output
# @see ModuleHelper#prune_method_listing
def generate_method_list; end

# Generate a searchable class list in the output
def generate_class_list; end

# Generate a searchable file list in the output
def generate_file_list; end

def generate_list_contents; end

# Generate the frame documentation in the output
def generate_frameset; end

# @api private
class TreeContext
  def initialize
    @depth = 0
    @even_odd = Alternator.new(:even, :odd)
  end

  def nest
    @depth += 1
    yield
    @depth -= 1
  end

  # @return [String] Returns a css pixel offset, e.g. "30px"
  def indent
    "#{(@depth + 2) * 15}px"
  end

  def classes
    classes = []
    classes << 'collapsed' if @depth > 0
    classes << @even_odd.next if @depth < 2
    classes
  end

  class Alternator
    def initialize(first, second)
      @next = first
      @after = second
    end

    def next
      @next, @after = @after, @next
      @after
    end
  end
end

# @return [String] HTML output of the classes to be displayed in the
#    full_list_class template.
def class_list(root = Registry.root, tree = TreeContext.new)
  ""
end
