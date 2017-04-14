Rails.application.routes.draw do
	namespace :api do
		get "tasty_search" => "tasty_search#tasty_search"
	end
end