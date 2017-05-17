# tvrename -S (--series) SERIESNAME -s (--season) SEASON_NR
require 'optparse'
require 'colorize'
require 'highline/import'
require 'pathname'

# TvRename
  options = {}

  OptionParser.new do |parser|
    parser.banner = 'Simple TV Show renamer'

    parser.on('-S', '--series SERIES', 'The series to rename') do |s|
      options[:series] = s
    end

    parser.on('-s', '--season SEASON', 'The Season of the series') do |s|
      options[:season] = s
    end

    parser.on('-d', '--dir DIR', 'The dir where the files are') do |dir|
      options[:dir] = dir
    end

    parser.on('-e', '--episode FIRST_EPISODE', 'The number of the first episode which should be renamed') do |e|
      options[:e] = e
    end
  end.parse!

  def pad(number)
    number.to_s.rjust(2, '0')
  end

  def rename_series(orig, series, season, episode)
    "#{File.dirname(orig)}/#{series} S#{pad(season)}E#{pad(episode)}#{File.extname(orig)}"
  end

  if options[:series] && options[:season]
    season = options[:season]
    series = options[:series]

    offset = 1;

    if options[:e]
      begin
        offset = options[:e].to_i
      rescue
        puts "Error".red + ": -e expects a number".chomp
        exit
      end
    end

    dir = options[:dir] ? Pathname.new(options[:dir]) : Pathname.new('.')
    episodes = []

    if dir.directory?
      dir.each_child do |f|
        episodes << Pathname.new(f).realpath
      end
    else
      puts 'Error'.red + ': specify a directory'
      exit
    end

    Dir.chdir(dir.dirname)

    episodes.sort!
    episodes.each_with_index do |episode, i|
      puts 'RENAMING:'.yellow + " #{episode} ".blue + '-> '.red +
          rename_series(episode, series, season, i + offset).chomp.green
    end

    exit unless HighLine.agree("\nThis will rename the files shown above. Do you want to proceed?")

    begin
      episodes.each_with_index do |episode, i|
        File.rename(episode, rename_series(episode, series, season, i + offset))
      end
    rescue
      puts "\nError! Could not rename files. Please check your permissions".chomp.red
    end

    puts "\nSuccessfully renamed files!".chomp.green
  else
    puts 'Usage: ' + 'tvrename'.green + ' -S "Game Of Thrones" -s 1'.chomp
  end
