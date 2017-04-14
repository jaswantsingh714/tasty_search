namespace :one_time_tasks do
	
	desc "cut short data to 50K"
	task :cut_short_data_to_50k => :environment do
		count = 0;
		limit = 50000;
		File.open("public/finefoods50K.txt", "w") {|file| file.truncate(0) }
		File.open("public/finefoods.txt",'r').each_line do |line|	
			File.open("public/finefoods50K.txt",'a') {|fc| fc.write(line)}
			if line == "\n"
				count = count+1;
			end
			if count == limit
				break;
			end		
		end
	end
	desc "move dataset to database"
	task :move_dataset_to_database => :environment do
		review = Review.new
		File.open("public/finefoods50K.txt",'r').each_line do |line|	
			
			if line.include?("product/productId: ") 
				review.product_id = line.gsub("product/productId: ","").gsub("\n","")
				next
			end
			
			if line.include?("review/userId: ") 
				review.user_id = line.gsub("review/userId: ","").gsub("\n","")
				next
			end
			if line.include?("review/profileName: ") 
				review.profile_name = line.force_encoding('iso8859-1').encode('utf-8').gsub("review/text: ","").gsub("review/profileName: ","").gsub("\n","")
				next
			end
			if line.include?("review/helpfulness: ") 
				review.helpfulness = line.gsub("review/helpfulness: ","").gsub("\n","")
				next
			end
			if line.include?("review/score: ") 
				review.score = line.gsub("review/score: ","").gsub("\n","").to_f
				next
			end
			if line.include?("review/time: ") 
				time = line.gsub("review/time: ","").gsub("\n","")
				review.time = DateTime.strptime(time,"%s")
				next
			end
			if line.include?("review/summary: ") 
				review.summary = line.force_encoding('iso8859-1').encode('utf-8').gsub("review/text: ","").gsub("review/summary: ","").gsub("\n","")
				next
			end
			if line.include?("review/text: ") 
				review.text = line.force_encoding('iso8859-1').encode('utf-8').gsub("review/text: ","").gsub("\n","")
				next
			end
			if line == "\n"
				if !review.product_id.nil? and !review.user_id.nil?
					review.save
				end
				review = Review.new
			end	
		end
		
	end
	desc "cache words"
	task :cache_words => :environment do
		i=1
		Rails.cache.write("$$$head$$$",Review.all.sort_by{|review| [review.score]}.reverse!.first(20).map{|a| [a.id,a.score]})
		Review.all.find_in_batches do |batch|
			batch.each do |review|
				(review.text + " " + review.summary).split(' ').uniq.each do |word1|

					word = ReviewHelper.trim_word(word1) rescue byebug
					if word == ""
						next
					end
					if Rails.cache.exist?(word)
						ids = Rails.cache.read(word)
						index = 0
						while index< ids.length and ids[index][1] > review.score
							index = index + 1
						end
						if index == ids.length
							ids.push([review.id,review.score])
						else
							ids.insert(index,[review.id,review.score])
						end
						Rails.cache.write(word,ids)
					else
						Rails.cache.write(word,[[review.id,review.score]])
					end
					
				end
				
			end
			puts i.to_s+"th batch complete"
			i = i+1
		end
	end
	desc "clear words cache"
	task :clear_words_cache => :environment do
		Review.all.each do |review|
			(review.summary + review.text).split(' ').each do |word|
				word = ReviewHelper.trim_word(word)
				if Rails.cache.exist(word)
					Rails.cache.delete(word)
				end
			end
		end
	end
	desc "generate test queries"
	task :generate_test_queries => :environment do
		File.open("public/sample_queries.txt", "w") {|file| file.truncate(0) }
		for i in 10.downto(1) do
			for j in 1..10000
				query = Review.order("RANDOM()").first(i)
				.map{|t| t.summary + t.text}.join(" ").split(" ").sample(i)
				.map{|word| ReviewHelper.trim_word(word)}
				File.open("public/sample_queries.txt",'a') {|fc| fc.write(query.join(",")+"\n")}
			end
			puts i.to_s + "completed"
		end
	end

end
