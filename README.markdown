Getting Started in Development
==============================

    cp config/database.sample.yml config/database.yml
    rake gems:install
    rake db:create:all db:schema:load

Run the specs:

    rake spec

Oh wait, there are massive spec failures. I'll try to hack on that later.

To use at http://localhost:3000/ :

* Add a user at http://localhost:3000/signup
* If you don't get a confirmation email (which you likely won't since you don't have the mail sending configured), check log/development.log for a copy of the confirmation email that would have been sent to you, copy and paste the activation url from it into the browser toolbar (should look like the following: http://tt.entp.com/activate/db61f839776898cedee72fcb9f87465d797e2e93 - of course, replace tt.entp.com with your dev server address.