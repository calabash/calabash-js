#!/usr/bin/env ruby
require 'fileutils'

unless system("./build.sh")
  puts "Failed build.sh"
  exit(false)
end

new_lines = []
lp_web_query = "CalabashJS/CalabashJSLib/LPWebQuery.h"
IO.read(File.expand_path(lp_web_query)).each_line do |line|
  if /LP_QUERY_JS/.match(line)
    puts "Found #{line}"
    line = line.strip
    new_js = IO.read('build/calabash-min.js').strip
    new_lines << %Q[static NSString *LP_QUERY_JS = @"#{new_js}";]
  else
    new_lines << line
  end
end
File.open(lp_web_query,'w') do |f|
  f.puts(new_lines)
end
