# Cloudinary Ruby Sample Projects #

## Basic sample

The basic sample uploads local and remote image files to Cloudinary and generates URLs for applying various image transformations on the uploaded files.

### Setting up

1. Before running the sample, copy the Cloud Name, API Key and API Secret configuration parametes from Cloudinary [Management Console](https://cloudinary.com/console) into `config.rb` file of the project.
1. Run `bundle install` in project directory to bring all the required gems.
1. Run the sample using `ruby basic.rb`.

## Basic sample using Rails

Similar to the basic sample from above, implemented using Rails. In addition to image uploads, this sample demonstrates using Cloudinary view helpers (e.g. `cl_image_tag`) to apply various image transformations from inside Rails views.

### Setting up

1. Download `cloudinary.yml` for you account from Cloudinary [Management Console](https://cloudinary.com/console) or by using this [direct link](https://cloudinary.com/console/cloudinary.yml).
1. Put the downloaded `cloudinary.yml` file into `config` directory of the project.
1. In project directory, run `bundle install` to bring all the required dependencies.
1. Run `rails server` to start the development server.
1. Open the demo page on http://localhost:3000.

## Additional resources ##

* [Cloudinary Rails integration](http://cloudinary.com/documentation/rails_integration)
* [Image transformations documentation](http://cloudinary.com/documentation/image_transformations)
* View helpers defined in [helper.rb](https://github.com/cloudinary/cloudinary_gem/blob/master/lib/cloudinary/helper.rb) are automatically available to Rails projects using the Cloudinary gem.
