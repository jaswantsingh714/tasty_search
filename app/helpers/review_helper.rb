module ReviewHelper
	def self.trim_word(word)
		return word.gsub(",","").gsub(".","").gsub(";","").gsub("!","").gsub(/"/,"").gsub("(","").gsub(")","").gsub("<","").gsub(">","").gsub("/","").downcase
	end
end