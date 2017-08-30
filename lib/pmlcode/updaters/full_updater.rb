class PMLCode::FullUpdater < PMLCode::Updater

  handles do |criteria|
    criteria.type == :full
  end

  private

  def update(match, already_wrote)
    full_path = directory(match)
    FileUtils.mkdir_p(full_path)
    success = false
    content = nil
    Dir.chdir(@options.app) do
      content = `git show origin/#{match[:chapter]}.#{match[:snapshot]}:#{match[:path]}`
      if already_wrote || @options.dry_run
        success = true
      else
        system "git archive 'origin/#{match[:chapter]}.#{match[:snapshot]}' | tar -x -C '#{full_path}'"
        success = $?
      end
    end
    success ? content : nil
  end

  def generate_update_id(match)
    "#{match[:chapter]}.#{match[:snapshot]}"
  end

end
