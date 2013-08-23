CurrencyTrader::Application.routes.draw do
  resources :trading_signals

  resources :trading_strategy_populations

  resources :trading_operations

  resources :trading_time_frames

  resources :TradingStrategyOperationsController

  resources :TradingStrategyPopulationsController

  resources :trading_accounts

  resources :trading_strategies

  resources :trading_strategy_sets

  match 'trading_strategy_populations/show_all_for/:id' => 'trading_strategy_populations#show_all_for'
  match 'trading_strategy_populations/deactivate/:id' => 'trading_strategy_populations#deactivate'
  match 'trading_strategy_populations/activate/:id' => 'trading_strategy_populations#activate'

  match 'trading_operations/show_all_for/:id' => 'trading_operations#show_all_for'

  match 'trading_strategies/chart/:id' => 'trading_strategies#chart'

  match 'trading_operations/chart/:id' => 'trading_operations#chart'
  # The priority is based upon order of creation:
  # first created -> highest priority.

  # Sample of regular route:
  #   match 'products/:id' => 'catalog#view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   match 'products/:id/purchase' => 'catalog#purchase', :as => :purchase
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Sample resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Sample resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Sample resource route with more complex sub-resources
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', :on => :collection
  #     end
  #   end

  # Sample resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end

  # You can have the root of your site routed with "root"
  # just remember to delete public/index.html.
  root :to => 'trading_operations#index'

  # See how all your routes lay out with "rake routes"

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  # match ':controller(/:action(/:id))(.:format)'
end
