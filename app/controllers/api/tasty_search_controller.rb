module Api
    class TastySearchController < ApplicationController
    	def tasty_search
    		if(params["tokens"].nil? && !params["tokens"].kind_of?(Array))
    			render :json =>{} , :status => 300
    			return
    		end
	    	results = Review.tasty_search_results_indexed(params["tokens"].uniq)
	    	render :json =>results , :status => 200
    	end
    end
end