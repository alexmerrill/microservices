#!/usr/bin/env ruby

require "pathname"
require 'json'
require 'optparse'
scriptLocation = File.expand_path(File.dirname(__FILE__))
require "#{scriptLocation}/wsu-functions.rb"

ARGV.options do |opts|
  opts.on("-d", "--dry-run")  { $dryrun = '--dryRun ' }
  opts.on("-p", "--path=val", String)  { |val| $b2path = val }
  opts.parse!
end

# Set up methods

def outcomereport(status)
  open("#{@targetdir}/OUTCOME_LOG.txt", "a") do |l|
    l.puts ''
    l.puts "Package: #{$packagename}\n"
    if status == 'pass'
      l.puts "No errors detected\n"
    elsif status == 'premis'
      log = JSON.parse(@premis_structure.to_json)
      if log.length > 1
        log['events'].each do |event|
          if event[0]['eventDetail'].include?('b2 sync')
            l.puts event[0]['eventDetail']
            l.puts event[0]['eventOutcome']
            l.puts ''
          end
        end
      else
        l.puts log['events'][0]['eventDetail']
        l.puts log['events'][0]['eventOutcome']
        l.puts ''
      end
    elsif status == 'fail'
      l.puts "Errors occured\n"
    end
  end
end

# Check for b2 path
if $b2path.nil?
  puts "Please enter a B2 path using the -p flag.".red
  exit
end

ARGV.each do |input_AIP|
  @target_path = Pathname.new(input_AIP)
  # Test for directory
  if ! @target_path.directory?
    puts "Input must be a directory! Exiting.".red && exit
  end
  $packagename = File.basename(@target_path)
  @targetdir = File.dirname(@target_path)
  b2_target = $b2path + '/' + $packagename
  logfile = @target_path + 'data' + 'logs' + "#{$packagename}.log"
  if File.exist?(logfile)
    @premis_structure = JSON.parse(File.read(logfile))
  end
  if $dryrun.nil?
   $command = 'b2 sync ' + '"' + @target_path.to_s + '" ' + '"' + b2_target + '"'
  else
   $command = 'b2 sync ' + $dryrun + '"' + @target_path.to_s + '" ' + '"' + b2_target + '"'
  end

  if system($command)
    green("SUCCESS!")
    if $dryrun.nil?
      log_premis_pass(input_AIP,'aip2b2.rb')
      system($command)
      outcomereport('premis')
    end
  else
    if $dryrun.nil?
      red("SUCCESS!")
      log_premis_fail(input_AIP,'aip2b2.rb')
      outcomereport('premis')
    end
  end
end
