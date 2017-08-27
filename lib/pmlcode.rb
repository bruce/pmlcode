require "nokogiri"
require "rainbow"

require "fileutils"

require "pmlcode/version"

module PMLCode
  autoload :CLI,     'pmlcode/cli'
  autoload :Updater, 'pmlcode/updater'
  autoload :Content, 'pmlcode/content'
  autoload :Display, 'pmlcode/display'
  autoload :Source,  'pmlcode/source'
end
