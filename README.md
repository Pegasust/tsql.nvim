# Treesitter QL

A Neovim plugin allowing users to perform workspace-wise operations (highlighting,
list processing, mutation) on existing Treesitter query in Scheme.

## Features

### Buffer selection (`require('tsql').buf_match`)

* Filter logic via `buf_match.{path,filetype,ext,any}`.

#### Combinators

* With Tacit programming `BufMatch.or_(buf_match.path("world"), BufMatch.not_(buf_match.ext("txt")))`
* With method pipelines `buf_match.path("world").or(buf_match.ext("txt").not_())`
* Hybrid works too `buf_match.path("world").or(BufMatch.not(buf_match.ext("txt")))`

### Node query (`require('tsql').token_select`)

Currently support string-passthru of Treesitter query in Scheme

`token_select.from_scm("function")`

### Sink (`require('tsql').sink_by`)

* Any `{sink: fun(self, QNode[]) -> void}` works!
* Processes all workspace nodes.
* Highlight specific patterns in your text with `sink_by.highlight()`. 
Clear all highlights by `require('tsql').clear_highlights()`
* Format and print your nodes with `M.sink_by.print()`. This allows you to easily inspect your nodes.
* Copy nodes to your clipboard with `M.sink_by.nvim_yank_buf()`.

#### Format (`require('tsql').format`)

- Type: `Format = fun(QNode[]): string`
- `display: Format`: Representation in a concise/DSL format. This is inspired by Rust's `Display` trait
- `dump: Format`: Pretty-print string format for Lua table. Think of this like RON for Rust, 
some language-native object representation.
- `debug: Format`: Aliased from `dump` so that it's consistent with Rust's `Debug` trait

#### Pre-sink list processing

WIP


## Usage

Here's a basic example of how to use tsql.nvim:

```lua
local ts = require('tsql')
-- ts.t(<buf_match>, <ts_query>, <sink>)
-- Matches all strings in our neovim workspace.
ts.t(ts.buf_match.any(), ts.ts_query.from_scm("string"), ts.sink_by.print())
```

## Installation

Use your favorite package manager to install the plugin. For example, with [vim-plug](https://github.com/junegunn/vim-plug):

```vim
Plug 'pegasust/tsql.nvim'
```

Don't forget to run `:PlugInstall` to actually install the plugin.

## Configuration

To configure tsql.nvim, you can provide a configuration table to the `M.setup` function. Here's an example:

```lua
local tsql = require('tsql')

tsql.setup({
  nvim_hl_group = "Search" -- defines the highlight group used for highlighting
})
```

By default, `nvim_hl_group` is set to "Search".

## Commands

The following commands are available:

* `:Noh` - Clear all highlights added by this plugin.
* `:lua local ts = require('tsql'); ts.t(<buf_match>, <ts_query>, <sink>)`: Perform tsql in Lua bindings
  * Example: `:lua local ts = require('tsql'); ts.t(ts.buf_match.any(), ts.ts_query.from_scm("string"), ts.sink_by.print())`
    * Prints all strings in all buffers reachable from `nvim`
    * Note that `ts.sink_by.print()` will use `ts.format.default`, which is `ts.format.display` without additional configurations

### TDSL (Work in progress)

* `:Tdsl */scm:string/p` - DSL without interacting with Lua API. This example 
prints all strings on all buffers in default (display) format

#### Advanced example (`feat:TDSL` + `feat:list_process`)

Highlight all strings within the current buffer that has more than one occurences

```
:Tdsl bufnr:0/scm:string/group_by(t:qnode:text) | values | filter(count | ge(2)) | flatten | h 
```

If you're a FP nerd, power to you! Here's the breakdown of the pre-sink processing:
- `group_by`: Group items in a list based on a key returned by a function.

Function Signature: `group_by(func: (item: T) -> K, list: T[]) -> Map<K, T[]>`

- `flatten`: Flatten a list of lists into a single list. `flatten([[a], [b, c], []]) -> [a, b, c]`

Function Signature: `flatten(list: T[][]) -> T[]`

- `values`: Creates an iterator that goes through all values of a map (created by `group_by` in this case)

Function Signature: `values(map: Map<K, V>) -> V[]`

- `filter_map`: Return a new list containing only the items where the given function maps to non-null

Function Signature: `filter_map(fn: (item: T) -> Option<T>) -> (T[] -> T[])`

- `some_if`: Lifts a predicate (`T -> bool`) into an "option predicate": `T -> Option<T>`

Function Signature: `some_if(fn: (item: T) -> bool) -> (T -> Option<T>)`

- `count`: Counts the number of elements in an interable 

Function Signature: `count(list: T[]) -> number`

- `ge`: A higher-order function to compare if a number is greater or equal to a set number. `ge(2)(3) == 3 >= 2`

Function Signature: `ge(lower: number) -> (number -> bool)`

## Documentation

For detailed information on each function and class, refer to the source code. 
It contains extensive inline documentation that should be enough to understand each part of the plugin.

## Contribution

If you want to contribute to the development of tsql.nvim, feel free to open a pull request.

## License

Tsql.nvim is distributed under the MIT license. See the LICENSE file in the repository for details.
