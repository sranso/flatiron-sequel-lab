https://gist.github.com/ashleygwilliams/fdb8340c8e6ce421975b
---
language: ruby
tags: ORM, sequel, migrations
---

# ORMs in General

By now you should already be familiar with the concept of an [ORM](http://en.wikipedia.org/wiki/Object-relational_mapping), and have written something of your own via the Dog Class.

Building your own little ORM for a single Class is a great way to learn about how object oriented programming languages commonly interface with a database, but imagine you had two, or three, or ten classes in your application that all corresponded to different tables in the database. Building those same kinds of methods into each of them would be a lot of work! Ok, maybe you're thinking: I bet I could just write one Class that would have methods that could work with any table, and use that instead. Go for it! Don't really though, that will become a lot of code really quick, and as your demands grow, maintance and stabilty will quickly become an issue as well! The best O/RM's develop over time and require a lot of testing. 

So, chances are, you just don't know enough about Ruby or databases yet to make something flexible or efficient enough to meet your needs as a professional web application developer. Not to worry, you're not the first person to have this problem, and there are already plenty of great libraries out there that will make your life easier. Meet [Sequel](http://sequel.rubyforge.org/), the database toolkit for Ruby!

Still confused? Let's take a quick look at what Sequel can do.

# Sequel ORM

Connect to a database:

```ruby
DB = Sequel.connect('sqlite://blog.db')
```
[http://sequel.rubyforge.org/rdoc/files/doc/opening_databases_rdoc.html](http://sequel.rubyforge.org/rdoc/files/doc/opening_databases_rdoc.html)

Create a table:

```ruby
Sequel.migration do
  change do
    create_table(:artists) do
      primary_key :id
      String :name
    end
  end
end
```
[http://sequel.rubyforge.org/rdoc/files/doc/schema_modification_rdoc.html](http://sequel.rubyforge.org/rdoc/files/doc/schema_modification_rdoc.html)

That's cool. But where it starts to get interesting is when you make use of Sequel's built-in O/RM utilities to extend your Ruby classes with Sequel's `Model` class.

With Sequel, and other O/RM's (such as ActiveRecord in Rails) the way this is managed is through [Class Inheritance](http://rubylearning.com/satishtalim/ruby_inheritance.html).

So to add `Sequel::Model`'s methods to your class you'd do:

```ruby
class Student < Sequel::Model
end
```

Now your `Student` class has a whole bunch of [new methods](http://sequel.rubyforge.org/rdoc/classes/Sequel/Model.html) available to it, that are already built in to Sequel.

Retrieve a list of all the columns in the table:

```ruby
Student.columns
#=> [:id, :name]
```

Create a new student:

```ruby
Student.create(name: 'Jon')
# INSERT INTO students (name) VALUES ('Jon')
```

Retrieve a Student from the database by id:

```ruby
Student[1]
```
[http://sequel.rubyforge.org/rdoc/classes/Sequel/Model/ClassMethods.html#method-i-5B-5D](http://sequel.rubyforge.org/rdoc/classes/Sequel/Model/ClassMethods.html#method-i-5B-5D)

Find by name, or any attribute

```ruby
Student.find(name: 'Jon')
# SELECT * FROM artists WHERE (name = 'Jon') LIMIT 1
```

or

```ruby
Student[name: 'Jon']
# SELECT * FROM artists WHERE (name = 'Jon') LIMIT 1
```
[http://sequel.rubyforge.org/rdoc/classes/Sequel/Model/ClassMethods.html#method-i-find](http://sequel.rubyforge.org/rdoc/classes/Sequel/Model/ClassMethods.html#method-i-find)


You can get or set attributes of instances of a Student once you have retrieved it:

```ruby
student = Student.find(name: 'Jon')
student.name
#=> 'Jon'

student.name = 'Steve'

student.name
#=> 'Steve'
```

And then save those changes to the database:

```ruby
student = Student.find(name: 'Jon')
student.name = 'Steve'
student.save
```

Note that our `Student` class doesn't have any methods defined for `#name` either. Nor does it make use of Ruby's built-in `attr_accessor` method. 

```ruby
class Student < Sequel::Model
end
```

So where do the methods for getting and setting 'name' get added? Where is the only place thus far you can think of that we've added something called name?

If you answered 'in the database' then you're on the right track. An O/RM's job is to be the glue between our database and our objects. In this case, Sequel is really smart and has made some assumptions for us. Sequel assumes its job is to make it so that you can interact with your rows in your database as Ruby objects. So if you want to read attributes of an object, or make changes to them, it assumes you're goal is to reflect those changes in the database.

Basically, Sequel is saying "Ok, I've got this class Student, it must map to a table called 'students.'" Then it's looking in the students table and for each column in that table, and adding methods for both getting and setting that attribute.

Without ever even needing to define the methods on your class, Sequel has given you the ability to get and set them just through a couple of clever assumptions/conventions. This technique is common of most Ruby O/RM's.

# Let's Learn About Migrations

## Objective

Create, connect to, and manipulate a SQLite database using the Sequel database toolkit for Ruby.

## Setup

1) Create a directory called 'sequel-lab' that will contain all the files we need for the project.

2) We're going to be using the sequel gem to create a mapping between our database and model, so let's add a Gemfile to the project so we can manage that with bundler.

```
# Gemfile
source 'https://rubygems.org'

gem 'sequel'
```

and then run `bundle` in terminal from the 'sequel-lab' directory.

## Migrations

Migrations are a convenient way for you to alter your database in a structured and organized manner. You could edit fragments of SQL by hand but you would then be responsible for telling other developers that they need to go and run them. You’d also have to keep track of which changes need to be run against the production machines next time you deploy.

Migrations also allow you to describe these transformations using Ruby. The great thing about this is that it is database independent: you don’t need to worry about the precise syntax of CREATE TABLE any more than you worry about variations on SELECT * (you can drop down to raw SQL for database specific features). For example you could use SQLite3 during development, but Postgres in production.

Another way to think of migrations is like version control for your database. You might create a table, add some data to it, and then make some changes to it later on. By adding a new migration for each change you make to the database, you won't lose any data you don't want to, and you can easily revert changes.

Executed migrations are tracked by Sequel in your database, so they aren't used twice. Using the migrations system to apply the schema changes is easier than keeping track of the changes manually and executing them manually at the appropriate time.

1) We'll want a place to keep all our migrations so create a folder in the 'sequel-lab' directory called 'migrations'

2) In the migrations directory, create a file called '01_create_artists.rb' (we'll talk about why we added the 01 later).

```ruby
# migrations/01_create_artists.rb

Sequel.migration do
  up do
  end

  down do
  end
end
```

Here we use Sequel's `#migration` method, which takes a block. Inside that block we use the `up` block to define what code to execute when the migration is run, and in the `down` block we define what code to execute when the migration is rolled back. Think of it like "do" and "undo."

These are the basics of a Sequel migration. They all have an up and a down, and since they are just Ruby code, they are capable of executing any arbitrary Ruby code as well, so something like:

```ruby
# migrations/create_artists.rb

Sequel.migration do
  up do
    puts "Hey you just ran the create_artist migration!"
  end

  down do
    puts "Hey you just rolled-back the create_artist migration!"
  end
end
```

Would be valid, though you probably wouldn't use a migration just to do a puts.

There is a third block available to use besides `up` and `down` we can use Sequel's `change` block.

```ruby
# migrations/create_artists.rb

Sequel.migration do
  change do
  end
end
```

Which is just short for do this, and then undo it on rollback. This only works for migrations the Sequel knows how to undo. So executing arbitrary Ruby won't work here. Let's look at creating the rest of the migration to generate our artists table and add some columns.

```ruby
# migrations/create_artists.rb

Sequel.migration do
  change do
    create_table(:artists) do
    end
  end
end
```

Here we've added the create_table method, and passed the name of the table we want to create as a symbol. Pretty simple, right? Other methods we can use here are things like `remove table`, `rename_table`, `remove_column`, `add_column` and others. See the list at for more: [http://sequel.rubyforge.org/rdoc/files/doc/migration_rdoc.html#label-A+Basic+Migration](http://sequel.rubyforge.org/rdoc/files/doc/migration_rdoc.html#label-A+Basic+Migration)

No point in having a table that has no columns in it, so lets add a few:

```ruby
# migrations/create_artists.rb

Sequel.migration do
  change do
    create_table(:artists) do
      primary_key :id
      String :name
      String :genre
      Integer :age
      String :hometown
    end
  end
end
```

Looks a little familiar? On the left we've given the data type we'd like to cast the column as, and on the right we've given the name we'd like to give the column. The only thing that seems a little weird is that `primary_key` is lowercase, because it's the name of a method and not the class name of a data type we'd like the values stored in our database cast as by our O/RM.

And that's it! You've created your first Sequel migration. Next, we're going to see it in action!

[Sequel Schema Modification Guide](http://sequel.rubyforge.org/rdoc/files/doc/schema_modification_rdoc.html)

3) Running migrations

The simplest way to run our migrations is with Sequel's built-in executable, from the command-line:

```bash
sequel -m migrations sqlite://artists.db
```

Where `migrations` is the path to our migrations, and `sqlite://artists.db` is the address to connect to our database. We haven't created a database yet but we're going let sqlite handle that for us automagically. So, again, just run:

```bash
sequel -m migrations sqlite://artists.db
```

and unless you got some error, you should be good to go!

4) Create the Artist class.

```ruby
# artist.rb

class Artist
end
```

Next, we'll extend the class with `Sequel::Model`

```ruby
# artist.rb

require 'sequel'

class Artist < Sequel::Model
end
```

Finally, we'll want to establish a connection to the database so our model has something to map to!

```ruby
# artist.rb

require 'sequel'

DB = Sequel.connect('sqlite://artists.db')

class Artist < Sequel::Model
end
```

Voila. You should now be able to interact with your database via your model!

To test it out, fire up irb and require artist.rb:

```bash
irb -r ./artist.rb
```

### Try out the following:

View that the class exists:

```ruby
Artist
#=> Artist
```

View that database columns:

```ruby
Artist.columns
#=> [:id, :name, :genre, :age, :hometown]
```

Instantiate a new Artist named Jon, set his age to 30, save him to the database:

```ruby
a = Artist.new(name: 'Jon')
#=> #<Artist @values={:name=>"Jon"}>

a.age = 30
#=> 30

a.save
#=> #<Artist @values={:id=>1, :name=>"Jon", :genre=>nil, :age=>30, :hometown=>nil}>
```

Instantiate and save a new Artist named Kelly:

```ruby
Artist.create(name: 'Kelly')
#=> #<Artist @values={:id=>2, :name=>"Kelly", :genre=>nil, :age=>nil, :hometown=>nil}>
```

Return an array of all Artists from the database:

```ruby
Artist.all
#=> [#<Artist @values={:id=>1, :name=>"Jon", :genre=>nil, :age=>30, :hometown=>nil}>, #<Artist @values={:id=>2, :name=>"Kelly", :genre=>nil, :age=>nil, :hometown=>nil}>]
```

Find an Artist by name:

```ruby
Artist.find(name: 'Jon')
#=> #<Artist @values={:id=>1, :name=>"Jon", :genre=>nil, :age=>30, :hometown=>nil}>
```

There are a number of methods you can now use to create, retrieve, update, and delete data from your database, and a whole lot more.

[http://sequel.rubyforge.org/rdoc/classes/Sequel/Model/ClassMethods.html](http://sequel.rubyforge.org/rdoc/classes/Sequel/Model/ClassMethods.html)

[http://sequel.rubyforge.org/rdoc/classes/Sequel/Model/InstanceMethods.html](http://sequel.rubyforge.org/rdoc/classes/Sequel/Model/InstanceMethods.html)

## Using migrations to manipulate existing tables

Here is another place where migrations really shine. Let's add a gender column to our artists table. Remember that Sequel keeps track of what migrations we've already run, so adding it to our 01_create_artists.rb won't work because it won't get executed when we run our migrations again.

To make this change we're going to need a new migration, which we'll call 02_add_gender_to_artists.rb.

```ruby
# 02_add_gender_to_artists.rb

Sequel.migration do
  change do
    add_column :artists, :gender, String
  end
end
```

Pretty awesome, right? We basically just told Sequel to add a column to the artists table, call it gender, and it's going to be a string.

Notice how we incremented the number in the file name there? Imagine for a minute that you deleted your original database and wanted to execute the migrations again. Sequel is going to execute each file, but it has to do so in some order and it happens to do that in alpha-numerical order. If we didn't have the numbers, our add_column migration would have tried to run first ('a' comes before 'c') and our artists table wouldn't have even been created yet! So we used some numbers to make sure they execute in order. In reality our two-digit system is very rudimentary. As you'll see later on, frameworks like rails have generators that create migrations with very acurate timestamps so you'll never have that problem.

Now that you've save the migration, back to the terminal to run it:

```bash
sequel -m migrations sqlite://artists.db
```

Awesome! Now open up irb:

```bash
irb -r ./artist.rb
```

and check it out:

```ruby
Artist.columns
=> [:id, :name, :genre, :age, :hometown, :gender]
```

Great!

Nope- wait. Word just came down from the boss- you weren't supposed to ship that change yet! OH NO! No worries, we'll rollback to the first migration using the `-M` switch:

```bash
sequel -m migrations -M 1 sqlite://artists.db
```

then double check:

```bash
irb -r ./artist.rb
```

```ruby
Artist.columns
=> [:id, :name, :genre, :age, :hometown]
```

Oh good your job is saved. Thanks Sequel! Now when the boss says it's actually time to add that column, you can just run it again!

```bash
sequel -m migrations sqlite://artists.db
```

Woohoo!