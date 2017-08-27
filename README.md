# pmlcode

A utility for downloading code files referenced by `.pml` files.

## Installation

    $ gem install pmlcode

## Usage

See `pmlcode --help`

### Example

Assuming `Chapter.pml` has an embed for
`code/02-testing/01-start/test/some_test.exs`:

This command:

    $ pmlcode Chapter.pml -a /path/to/git/working/copy

Will generate the referenced file, extracting it from the
`origin/02-testing.01-start` ref of `/path/to/git/working/copy`.

You can also extract the entire branch using the `-t full` option,
process as many `.pml` files as you like at once, customize the
pattern used to extract the metadata from the filename, and more.

See `pmlcode --help` for more details (or read `USAGE`
in [PMLCode::CLI](./lib/pmlcode/cli.rb)).

## Contributing

Bug reports and pull requests are welcome on GitHub at
https://github.com/bruce/pmlcode.

## License

The gem is available as open source under the terms of
the [MIT License](http://opensource.org/licenses/MIT).
