class Review < ActiveRecord::Base
	def self.query_results_count 
		return 20
	end
	def self.tasty_search_results tokens
		results = Review.all.sort_by{|review| [review.match_scores(tokens),review.score]}.reverse!.first(query_results_count)
	end

	def self.tasty_search_results_indexed tokens
		hash = {}
		Rails.cache.read("$$$head$$$").each do |val|
			hash[val[0]] = [0,val[1]] 
		end

		tokens.each do |token|
			list = Rails.cache.read(token)
			if(!list.nil?)
				hash_temp = {}
				puts list.size()
				list.each do |review|
					if !hash_temp.key?(review[0])
						hash_temp[review[0]] = true
						if hash.key?(review[0])
							hash[review[0]][0] = hash[review[0]][0] + 1
						else
							hash[review[0]] = [1,review[1]]
						end
					end
				end
			end
		end
		ids = hash.sort_by{|k,v| [-v[0],-v[1]]}.first(query_results_count).map{|a| a[0]}
		results = Review.where(id: ids)
	end

	def self.bench_mark()
		
		query_array = []
		File.open("public/sample_queries.txt", "r").each_line do |query|
			query = query.split(',')
			query_array.push(query)	
		end

		puts "started"
		start = Time.now
		i=0
		query_array.each do |query|
			tasty_search_results_indexed(query)
			i = i+ 1
			if i%1000 == 0
				puts "Single batch completed in " + ((Time.now-start)*1000).to_s
			end
		end
		puts ((Time.now-start)*1000).to_s + "miliseconds"
	end

	def match_scores tokens
		score = 0.0;

		if tokens.size == 0
			return 0
		end
		tokens.each do |token|
			if(self.text.include?(token) || self.summary.include?(token))
				score = score+1.0
			end
		end
		return score/(tokens.size)
	end
end
