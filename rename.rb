patt = ARGV[0]
replace = ARGV[1]
files = ARGV[2..-1]
files.each do |file|
  name = File.basename(file)
  dir_name = File.dirname(file)
  new_path = "#{dir_name}/#{name.gsub(patt, replace)}"
  File.rename(file, new_path)
end