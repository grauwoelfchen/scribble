# Scribble

File based command line todo application.

## Installation

```
$ gem install scribble

or

$ git clone https://github.com/grauwoelfchen/scribble.git
$ cd scribble
$ rake build
$ gem install pkg/scribble-x.x.x.gem
```

## Usage

![http://farm9.staticflickr.com/8300/7750573776_9184dee824.jpg](http://farm9.staticflickr.com/8300/7750573776_9184dee824.jpg)

see --help

```
$ scribble --help
Usage: scribble {add|edit|delete|(un)done|init|list|(un)mark|say} [options]
See `scribble <command> --help` for more information on a specific command.
Global options
    -v, --version      Show version
    -h, --help         Display this help message.
```

All your todos and settigs are stored into a `.scribble` file in current directory.  
columns are TASK;DONE;MARK;DATETIME

```
$ cat .scribble
Colorize output;0;1;2012-08-06 12:04:25 +0900
Update test case :);0;1;2012-08-06 15:25:57 +0900
Create done action;0;0;2012-08-06 20:16:25 +0900
Create marking (as important) action;0;0;2012-08-06 20:17:57 +0900
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
## 9 tasks
+ [00] Colorize output                        2012-08-06 12:04:25 +0900
- [01] Update test case :)                    2012-08-06 15:25:57 +0900
+ [02] Create done action                     2012-08-06 20:16:25 +0900
+ [03] Create marking (as important) action   2012-08-06 20:17:57 +0900
- [04] Create clear method                    2012-08-08 00:55:20 +0900
  [05] Refactor Cli class :(                  2012-08-08 00:56:56 +0900
  [06] Create action alias                    2012-08-08 00:57:29 +0900
+ [07] Create say action                      2012-08-08 23:04:48 +0900
  [08] Add undone only option for list action 2012-08-11 01:41:58 +0900
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
