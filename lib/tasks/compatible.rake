namespace :compatible do
  desc 'Upcase all country flag png file names for cross platform compatible.'
  task upcase_flag_png_files: :environment do
    flags_base_path = "#{Rails.root}/public/images/flags_iso"

    unless File.directory?(flags_base_path)
      puts "[Error] Can not find flags_base_path: #{flags_base_path}"
      return
    end

    Dir.chdir flags_base_path

    sub_dirs = Dir.entries(flags_base_path) - %w(. ..)

    if sub_dirs.empty?
      puts '[Error] No sub directories in flags_base_path !'
      return
    end

    sub_dirs.each do |dir|
      unless dir =~ /^\d+$/
        puts "[Action] Ignore illegal sub directory: #{dir}"
        next
      end

      puts "[Action] Enter sub directory: #{dir} ..."
      Dir.chdir("#{flags_base_path}/#{dir}")
      png_files = Dir.glob('*.png')
      puts "[Info] #{png_files.length} png files found."
      renamed_count = 0

      png_files.each do |file|
        if file =~ /^([a-z]{2})\.png$/
          File.rename(file, $1.upcase + '.png')
          renamed_count += 1
        end
      end

      puts "[Info] #{renamed_count} png files renamed!"
    end
  end

end
