require 'mkmf'

OPENRING_LIST="openring/feed_list.txt"
OPENRING_IN="openring/openring_template_in.html"
OPENRING_OUT="_includes/openring_template_out.html"

OUT_FORMAT = "-" * 80

def openring_out_file_exist?()
  return true if File.exist?(OPENRING_OUT)
  return false
end

def file_was_created_more_than_x_min?(interval_min = 15)
  file_created_at_sec = File.mtime(OPENRING_OUT).tv_sec
  time_now_sec = Time.now.tv_sec

  elapsed_time_min = (time_now_sec - file_created_at_sec) / 60

  return true if elapsed_time_min >= interval_min
  return false
end

def composing_openring_command(openring_path)
  openring_custom_parameters = ''

  File.foreach(OPENRING_LIST) do |line|
    openring_custom_parameters += " -s #{line.chomp}"
  end

  return "#{openring_path} #{openring_custom_parameters} < #{OPENRING_IN} > #{OPENRING_OUT}"
end

# ---------------------------------------------------------------------------------------------------------------------------

# [*] What is the post_read event on that hook?

# post_read reads all files before building the site, i.e, when we
# run the "jekyll build server" it executes the code block written 
# in the hook and then builds the site.

# In this case we check the existence of the OPENRING_OUT file,
# if the file doesn't exist it is created through this hook.

# ---------------------------------------------------------------------------------------------------------------------------

Jekyll::Hooks.register :site, :post_read do
  unless openring_out_file_exist?
    puts(OUT_FORMAT)

    File.write(OPENRING_OUT,"")

    puts("[!] #{OPENRING_OUT} was created.")

    puts(OUT_FORMAT)
  end
end

# ---------------------------------------------------------------------------------------------------------------------------

# [*] What is the post_write event on that hook?

# The post_write event of the hook is called after writing all
# rendered files to disk.

# In this case this hook is used to run the openring command
# to create the OPENRING_OUT output file every 15 minutes.

# ---------------------------------------------------------------------------------------------------------------------------

Jekyll::Hooks.register :site, :post_write do
  openring_path = find_executable('openring')

  if openring_path == nil
    puts(OUT_FORMAT)

    puts("[!] you don't have openring installed.")
    puts("git clone https://git.sr.ht/~sircmpwn/openring")
    puts("go build -o openring")
    puts("sudo cp openring /usr/local/bin/")

    puts(OUT_FORMAT)

  elsif file_was_created_more_than_x_min?
    puts(OUT_FORMAT)

    puts("[!] keep calm, we're running openring...")
    openring_cmd = composing_openring_command(openring_path)
    system(openring_cmd)

    puts(OUT_FORMAT)
  end
end
