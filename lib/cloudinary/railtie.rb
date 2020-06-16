class Cloudinary::Railtie < Rails::Railtie
  rake_tasks do
    Dir[File.join(File.dirname(__FILE__),'../tasks/**/*.rake')].each { |f| load f }
  end
  config.after_initialize do |app|
    ActionView::Base.send :include, CloudinaryHelper
  end

  ActiveSupport.on_load(:action_controller_base) do
    ActionController::Base.send :include, Cloudinary::CloudinaryController
  end
end
