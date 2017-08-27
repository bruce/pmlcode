class PMLCode::FullUpdater < PMLCode::Updater

  handles do |criteria|
    criteria.type == :full
  end

  private

  def update(match)
    full_path = directory(match)
    FileUtils.mkdir_p(full_path)
    success = false
    Dir.chdir(@options.app) do
      system "git archive '#{match[:chapter]}.#{match[:snapshot]}' | tar -x -C '#{full_path}'"
      success = $?.success?
    end
    success
  end

  def generate_update_id(match)
    "#{match[:chapter]}.#{match[:snapshot]}"
  end

end
