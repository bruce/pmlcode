require 'ostruct'
require 'optparse'

module PMLCode::CLI

  USAGE =<<-EOU
  ## USAGE

      pmlcode [--export EXPORT_PATH] | [PML_PATH, ...] [OPTIONS]

  PML_PATHs can optionally include a :LINENUM suffix.

  ## SYNOPSIS

  Looks for `<embed>` tags whose `file` attribute match `--pattern`, extracting the
  following metadata:

  - `coderoot`: The relative path from the source PML's directory
  - `chapter`: A chapter identifier
  - `snapshot`: A snapshot of the code at a specific point in the chapter
  - `path`: The path to the file within the target `--application-directory` project

  For example, given this embed, using the default --pattern:

    <embed file="code/02-testing/01-start/test/some_test.exs"/>

  This is the metadata:

  coderoot
  : `code`

  chapter
  : `02-testing`

  snapshot
  : `01-start`

  path
  : `test/some_test.exs`

  This file will be extracted by looking at the repository located at --application-directory,
  and trying to find a ref _on its remote origin_ that matches the `chapter.snapshot`, i.e.:

      `origin/02-testing.01-start`

  Then pulling `test/some_test.exs` (or the entire branch, if `--type full` is being used).

  ## ENVIRONMENT VARIABLES

  PMLCODE_APP_DIR
  : An optional working copy directory path, sets the default
    for `--application-directory`

  PMLCODE_PATTERN
  : An optional pattern, sets the default for `--pattern`

  ## CUSTOM PATTERNS

  Any custom pattern must have named captures for `coderoot`, `chapter`, `snapshot`, and `path`.

  ## CUSTOM BRANCH/REFS

  Currently the ref retrieved from git repositories is always in the form `chapter.snapshot`,
  using the information matched using the --pattern.

  ## OPTIONS

  EOU

  DEFAULT_PATTERN = /^(?<coderoot>[^\/]+)\/(?<chapter>[^\/]+)\/(?<snapshot>[^\/]+)\/(?<path>.+)$/

  DEFAULTS = {
    type: :sparse,
    app: ENV["PMLCODE_APP_DIR"],
    pattern: ENV["PMLCODE_PATTERN"] ? Regexp.new(ENV["PMLCODE_PATTERN"]) : DEFAULT_PATTERN
  }.freeze

  def self.run(args)
    options = OpenStruct.new(DEFAULTS)
    # Parse arguments
    parser = build_parser(options)
    parser.parse!(args)

    check_app!(options)

    if options.export
      PMLCode::ExportCommand.run(options)
    else
      PMLCode::UpdateCommand.run(options, parser, args)
    end

  end

  private

  def self.check_app!(options)
    unless options.app
      $stderr.puts "No --application-directory given."
      $stderr.puts parser
      exit
    end
  end

  def self.build_parser(options)
    OptionParser.new do |opts|
      opts.banner = USAGE

      opts.on("-t [TYPE]", "--type", [:sparse, :full], "Export type (sparse, full; default: #{options.type})") do |value|
        options.type = value
      end

      opts.on("-a [PATH]", "--application-directory", "Application directory (default: #{options.app || "NONE"})") do |value|
        options.app = value
      end

      opts.on("-p [PATTERN]", "--pattern", "Pattern (default: \"#{options.pattern.source}\")") do |value|
        options.pattern = Regexp.new(value)
      end

      opts.on('-c', '--content', "Show content") do
        options.content = true
      end

      opts.on("-V", "--verbose", "Verbose output (Only useful with --content)") do
        options.verbose = true
      end

      opts.on('--dry-run', "Dry run (do not write files)") do
        options.dry_run = true
      end

      opts.on('--export EXPORT_PATH', "Export all code branches to a cleaned-up Git repository at EXPORT_PATH") do |path|
        options.export = path
      end

      opts.on_tail("-h", "--help", "Show this message") do
        puts opts
        exit
      end

    end
  end

end
