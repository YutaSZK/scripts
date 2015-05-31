require 'yaml'
require 'pry'

path = ARGV[0]
file = File.open(path)
amulets = Array.new
file.each_line do |line|
  arr = line.chomp.split(',')
  amulets << arr
end

skills = YAML.load_file('skill_sim/skills.yml')

amulets.each do |amu|
  if amu[5] && amu[5].to_i > amu[3].to_i
    amu[2..5] = amu[4], amu[5], amu[2], amu[3]
  end
end

amulets.sort_by! do |amu|
  [skills[amu[2]], amu[3].to_i, amu[1].to_i]
end
amulets.reverse!

out_amulets = amulets.map! { |amu|amu.join(',')}

f = File.open('skill_sim/out_amulets.txt', 'w')
out_amulets.each { |amu| f.write("#{amu}\n") }