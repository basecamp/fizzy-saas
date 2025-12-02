Fizzy::Saas::Engine.routes.draw do
  Queenbee.routes(self)

  scope :integrations, module: :integrations do
    resource :basecamp, only: %i[ new create destroy ], as: :basecamp_integration do
      scope module: :basecamps do
        resource :callback, only: :show
      end
    end
  end
end
