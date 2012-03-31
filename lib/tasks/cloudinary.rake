namespace :cloudinary do
  desc "Sync static resources with cloudinary"
  task :sync_static do
    Cloudinary::Static.sync
  end
end