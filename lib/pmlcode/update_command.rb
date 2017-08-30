module PMLCode::UpdateCommand

  REQUIRED_PATTERN_CAPTURES = %w(coderoot chapter snapshot path)

  def self.run(options, parser, args)
    sources = prepare(options, parser, args)

    sources.each do |source|
      options.source = source
      options.output = File.dirname(source.path)
      update!(options)
    end
  end

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

end
