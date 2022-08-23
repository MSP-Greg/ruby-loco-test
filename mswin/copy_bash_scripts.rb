# frozen_string_literal: true

module CopyBashScripts
  BIN_DIR = "#{RbConfig::TOPDIR}/bin"

  SRC_DIR = "#{Dir.pwd}/src/bin"

  class << self

    def run
      # clean empty gem folders, needed as of 2019-10-20
      ary = Dir["#{Gem.dir}/gems/*"]
      ary.each { |d| Dir.rmdir(d) if Dir.empty?(d) }

      bash_preamble = <<~BASH.strip.rstrip
        {
          bindir=$(dirname "$0")
          exec "$bindir/ruby" "-x" "$0" "$@"
        }
        #!/usr/bin/env ruby
      BASH

      windows_script = <<~BAT
        @ECHO OFF
        @"%~dp0ruby.exe" -x "%~dpn0" %*
      BAT

      # all files in bin folder
      bins = Dir["#{BIN_DIR}/*"].select { |fn| File.file? fn }

      bash_bins = bins.select { |fn| File.extname(fn).empty? }

      bash_bins.each do |fn|
        str = File.read(fn, mode: 'rb:UTF-8').sub(/^#![^\n]+ruby/, bash_preamble)
        File.write fn, str, mode: 'wb:UTF-8'
        File.chmod 755, fn
      end

      windows_bins = bins.select { |fn| File.extname(fn).match?(/\A\.bat|\A\.cmd/) }

      windows_bins.each do |fn|
        # 'gem' bash script doesn't exist
        bash_bin = "#{BIN_DIR}/#{File.basename fn, '.*'}"
        unless File.exist? bash_bin
          ruby_code = File.read(fn, mode: 'rb:UTF-8').split(/^#![^\n]+ruby/,2).last.lstrip
          File.write bash_bin, "#{bash_preamble}\n#{ruby_code}", mode: 'wb:UTF-8'
          File.chmod 755, bash_bin
          puts "Created file #{bash_bin}"
        end

        File.write fn, windows_script, mode: 'wb:UTF-8'
        File.chmod 755, fn
      end
    end
  end
end
CopyBashScripts.run
