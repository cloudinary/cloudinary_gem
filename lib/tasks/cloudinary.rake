namespace :cloudinary do
  desc "Sync static resources with cloudinary"
  task :sync_static => :environment do
    delete_missing = ENV["DELETE_MISSING"] == 'true' || ENV["DELETE_MISSING"] == '1'
    Cloudinary::Static.sync(:delete_missing=>delete_missing)
  end
end
