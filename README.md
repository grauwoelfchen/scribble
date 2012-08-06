# Scribble

File based command line todo application.

## Installation

```
$ gem install scribble
```

## Usage

see --help

```
$ scribble --help
Usage: scribble {add|edit|init|list} [options]
See `scribble <command> --help` for more information on a specific command.
Global options
    -v, --version      Show version
    -h, --help         Display this help message.
```

All your todos and settigs are stored into a `.scribble` file in current directory.

```
$ cat .scribble
Colorize output;2012-08-06 12:04:25 +0900
Update test case:);2012-08-06 15:25:57 +0900
Create done action;2012-08-06 20:16:25 +0900
Create marking (as important) action;2012-08-06 20:17:57 +0900
---
:option:
  :number: 
  :random: false
:max_width: 51
:min_width: 3
```

## Test

```
$ bundle exec rspec
$ bundle exec rspec -f documentation  
```

## Todo

```
$ scribble list
00 Colorize output                      2012-08-06 12:04:25 +0900
01 Update test case:)                   2012-08-06 15:25:57 +0900
02 Create done action                   2012-08-06 20:16:25 +0900
03 Create marking (as important) action 2012-08-06 20:17:57 +0900
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
