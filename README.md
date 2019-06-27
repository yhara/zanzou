# Zanzou

Something like Ruby port of immer.js

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'zanzou'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install zanzou

## Usage

```rb
require 'zanzou'
orig_obj = {a: 1, b: 2}
p Zanzou.with_updates(orig_obj){|o| o[:b] = 3}
# => {a: 1, b: 3}
p orig_obj
# => {a: 1, b: 2}
```

Or you can just call `.with_updates` by requir'ing `zanzou/install`.

```rb
require 'zanzou/install'
orig_obj = {a: 1, b: 2}
p orig_obj.with_updates{|o| o[:b] = 3}
p orig_obj
```

## Supported classes

Zanzou should work well with these objects.

- Hash, String, numbers, true, false, nil

Array is also supported but has some problems left (see below).

Normally other objects, say a Range, should be OK too. However, container
classes (i.e. objects which contains other objects in it) need special
treatment to be used with Zanzou.

Steps to add support for a container class:

1. Define `class XxxShadow < Zanzou::ShadowNode` 

See spec/zanzou_spec.rb for an example.

## Known issues

Supporting Array is harder than I thought. Some methods of Array like `shift`,
`sort!`, etc. changes indices of existing values and thus affects the
parent-child relationship.

Example:

```rb
orig = [1, 2, [3]]
new_obj = Zanzou.with_updates(orig){|o|
  o.last[0] = 99   # Zanzou could memorize the child array is modified, but
  o.sort!          # its index is moved to somewhere
}
```

Maybe we could support this by tracking changes of indices (For example, `shift` changes all the indices by -1). For the case of `sort!` we could not expect how
the indices change, but maybe we can know the new position by comparing `object_id`. Otherwise we should just raise an error for these cases.

immer.js does not have such problems because ES6 Proxy is very powerful - it
reports object set/get even for methods like Array sort.

```js
const hooks = {
    get(target, prop, receiver) {
      console.log({hook: "get", prop})
      return target[prop];
    },
    set(target, prop, value) {
      console.log({hook: "set", prop, value})
      return target[prop] = value;
    }
};

const obj = [5613,2348,2987,2387,7823,1987];
const pxy = new Proxy(obj, hooks);
pxy.sort();

// Output:
//   ...
//   { hook: 'get', prop: '4' }
//   { hook: 'get', prop: '5' }
//   { hook: 'set', prop: '0', value: 1987 }
//   { hook: 'set', prop: '1', value: 2348 }
//   { hook: 'set', prop: '2', value: 2387 }
//   { hook: 'set', prop: '3', value: 2987 }
//   { hook: 'set', prop: '4', value: 5613 }
//   { hook: 'set', prop: '5', value: 7823 }
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/yhara/zanzou.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
