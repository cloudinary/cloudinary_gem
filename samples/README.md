# Cloudinary Ruby Sample Projects #

## Basic sample

The basic sample uploads local and remote image to Cloudinary and generates URLs for applying various image transformations on the uploaded files.

### Setting up

1. Before running the sample, copy the Cloud Name, API Key and API Secret configuration parameters from Cloudinary's [Management Console](https://cloudinary.com/console) of your account into `config.rb` file of the project.
1. Run `bundle install` in project directory to bring all the required GEMs. For the basic sample, you can also simply run `gem install cloudinary`.
1. Run the sample using `ruby basic.rb`.

## Basic sample for Rails

Similar to the basic sample described above, implemented as a Rails project. In addition to image uploads, this sample application demonstrates the usage of Cloudinary's view helpers (e.g. `cl_image_tag`) to apply various image transformations inside Rails views.

### Setting up

1. Download `cloudinary.yml` for your account from Cloudinary's [Management Console](https://cloudinary.com/console) or by using this [direct link](https://cloudinary.com/console/cloudinary.yml).
1. Place the downloaded `cloudinary.yml` file into the `config` directory of the project.
1. In the project directory, run `bundle install` to install all the required dependencies.
1. Run `rails server` to start the development server.
1. Open the sample page in a browser: http://localhost:3000

## Photo Album sample

Simple application for uploading images and displaying them in a list. Implemented using Rails and [CarrierWave](https://github.com/jnicklas/carrierwave) GEM for uploads.

### Setting up

1. Download `cloudinary.yml` for your account from Cloudinary's [Management Console](https://cloudinary.com/console) or by using this [direct link](https://cloudinary.com/console/cloudinary.yml).
1. Place the downloaded `cloudinary.yml` file into the `config` directory of the project.
1. In the project directory, run `bundle install` to install all the required dependencies.
1. Run `rake db:create` and `rake db:migrate` to create the database for the project.
1. Run `rake cloudinary:fetch_assets` to fetch the latest JavaScript library files and create the JavaScript index files
1. Run `rails server` to start the development server.
1. Open the sample page in a browser: http://localhost:3000

## Additional resources ##

* [Ruby on Rails integration documentation](http://cloudinary.com/documentation/rails_integration)
* [Image transformations documentation](http://cloudinary.com/documentation/image_transformations)
* View helpers defined in [helper.rb](https://github.com/cloudinary/cloudinary_gem/blob/master/lib/cloudinary/helper.rb) are automatically available to Rails projects.
* [CarrierWave integration documentation](http://cloudinary.com/documentation/rails_integration#carrierwave)
* [RailsCasts episode on CarrierWave](http://railscasts.com/episodes/253-carrierwave-file-uploads)
