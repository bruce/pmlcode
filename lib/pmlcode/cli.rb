require 'ostruct'
require 'optparse'

module PMLCode::CLI

  USAGE =<<-EOU
  ## USAGE

      pmlcode [PML_PATH, ...] [OPTIONS]

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

  REQUIRED_PATTERN_CAPTURES = %w(coderoot chapter snapshot path)
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

    sources = prepare(options, parser, args)

    sources.each do |source|
      options.source = source
      options.output = File.dirname(source.path)
      update!(options)
    end

  end

  private

  def self.update!(options)
    updater = PMLCode::Updater.find(options)
    unless updater
      $stderr.puts "No updater found. --type '#{options.type}' may not be supported."
      $stderr.puts parser
      exit
    end
    updater.run(options)
  end

  def self.prepare(options, parser, args)
    if args.empty?
      $stderr.puts "No PML files given."
      $stderr.puts parser
      exit
    end
    unless options.app
      $stderr.puts "No --application-directory given."
      $stderr.puts parser
      exit
    end
    unless REQUIRED_PATTERN_CAPTURES.all? { |cap| options.pattern.named_captures.key?(cap) }
      $stderr.puts "Pattern does not define one or more required named captures: #{REQUIRED_NAMED_CAPTURES}"
      $stderr.puts "Check your use of --pattern or the PMLCODE_PATTERN environment variable"
      $stderr.puts parser
      exit
    end
    sources = args.map { |pml| PMLCode::Source.parse(pml) }
    missing = sources.select(&:missing?)
    unless missing.empty?
      $stderr.puts "PML sources #{missing} not found"
      puts parser
      exit
    end
    sources
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

      opts.on('-x', '--dry-run', "Dry run (do not write files)") do
        options.dry_run = true
      end

      opts.on_tail("-h", "--help", "Show this message") do
        puts opts
        exit
      end

    end
  end

end
