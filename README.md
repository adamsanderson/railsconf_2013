Postgres, the Best Tool You're Already Using
============================================

This code is meant to supplement my RailsConf presentation.  In brief the
ActiveRecord models demonstrate some simple ways to use Postgres' support
for arrays, hashes, and full text search to build some useful features such
as tagging, hierarchies (tree structures), capture custom data, and search
user content.

After the presentation, I will make the slides available here as well.

* Ruby 2.0 (1.9 should work fine though)
* Rails 4.0.0 beta 1
* Postgres 9.x with the `pg` gem

Setup:
------

* `bundle install` will load the required gems (`rails v4.0.0` and `pg`)
* `rake db:create` to create the database
* `rake db:migrate` to ensure migrations have run
* `rake test` will then perform the tests

To experiment with the models use the rails console: `rails c`.  If you want to use it with the test data,
run `rails c test`.

If you have any questions, feel free to contact me.

    adam sanderson
    netghost@gmail.com