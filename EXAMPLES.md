# Anchormodel in the wild

This document takes you on a tour of how to unleash the power of Anchormodel in a production codebase. Each pattern below shows what an Anchormodel adds over a plain Rails Enum and includes a short, anonymized example you can adapt.

If all you need is a simple key-to-label mapping, a Rails Enum is perfectly adequate. The real value of Anchormodel emerges as soon as the entries in your enum need to *do* something: carry data, hold behavior, transition between states, reference one another, dispatch to other classes, or register themselves at load time.

---

## Table of contents

1. [Plain enumeration](#1-plain-enumeration)
2. [Ordered enumeration with `Comparable`](#2-ordered-enumeration-with-comparable)
3. [Rich behavior — calculations and helpers per entry](#3-rich-behavior--calculations-and-helpers-per-entry)
4. [State machine with allowed transitions](#4-state-machine-with-allowed-transitions)
5. [Multi-key collection attribute](#5-multi-key-collection-attribute)
6. [Cross-anchormodel references](#6-cross-anchormodel-references)
7. [Dynamic / conditional registration](#7-dynamic--conditional-registration)
8. [Polymorphic class registry](#8-polymorphic-class-registry)
9. [Mapping external-data payloads to anchormodels](#9-mapping-external-data-payloads-to-anchormodels)
10. [Gem-internal DSL with self-registration](#10-gem-internal-dsl-with-self-registration)

---

## 1. Plain enumeration

This is the simplest use of Anchormodel: a drop-in replacement for a Rails Enum when you want the keys to be stored as Strings in the database. There is no per-entry behavior — just a closed set of valid values.

```ruby
# app/anchormodels/shipment_status.rb
class ShipmentStatus < Anchormodel
  new :pending
  new :ready
  new :in_transit
  new :delivered
  new :cancelled
end

# app/models/order.rb
class Order < ApplicationRecord
  belongs_to_anchormodel :shipment_status
end
```

```ruby
order.shipment_status        # => #<ShipmentStatus<in_transit>>
order.delivered?             # => false
Order.in_transit             # => scope
Order.where(shipment_status: %i[ready in_transit])  # bulk where
```

You might wonder why you would reach for an Anchormodel here rather than a plain Rails Enum. There are three good reasons. First, the keys are stored as readable strings rather than as integer codes, which makes debugging in `psql` or `mysql` far easier. Second, adding behavior to the enum later requires no migration — you simply add methods to the class. And third, `ShipmentStatus.all` returns first-class Ruby objects that you can pass directly to form helpers, presenters, or service objects without writing translation layers.

---

## 2. Ordered enumeration with `Comparable`

When the entries in your enum have a natural ordering — permission levels, plan tiers, severity ranks — you can include `Comparable` and define `<=>` so that `<`, `>`, and `==` all work between instances.

```ruby
# app/anchormodels/role.rb
class Role < Anchormodel
  include Comparable

  attr_reader :privilege_level

  def <=>(other)
    privilege_level <=> other.privilege_level
  end

  new :guest,     privilege_level: 0
  new :member,    privilege_level: 1
  new :moderator, privilege_level: 2
  new :admin,     privilege_level: 3
end
```

```ruby
# Privilege checks now read like English:
def can_edit?(actor, target)
  actor.role > target.role
end

# Sort users by privilege:
User.all.sort_by(&:role)

# Pick the highest-privileged user in a group:
group.members.max_by(&:role)
```

Trying to model this with a Rails Enum would force you to either compare integer codes directly (which is a leaky abstraction — the code that compares roles should never need to know that `:admin` happens to be backed by `3`) or to scatter helper methods like `admin?`, `at_least_moderator?`, and so on across the `User` model. The Anchormodel version keeps the ordering logic in exactly one place: the enum itself.

---

## 3. Rich behavior — calculations and helpers per entry

When each entry needs to carry domain data *and* the methods that operate on that data, Anchormodel becomes a natural home for both. A classic example is a tax-rate enum where each rate knows how to convert between net and gross prices.

```ruby
# app/anchormodels/tax_rate.rb
class TaxRate < Anchormodel
  attr_reader :percentage

  new :exempt,   percentage: 0.0
  new :reduced,  percentage: 2.5
  new :standard, percentage: 8.1

  def label
    "#{super} (#{percentage}%)"
  end

  def factor
    percentage / 100.0
  end

  def gross_from_net(net)
    net.to_f * (1 + factor)
  end

  def net_from_gross(gross)
    gross.to_f / (1 + factor)
  end

  def tax_amount_from_gross(gross)
    gross.to_f * factor / (1 + factor)
  end
end
```

```ruby
product.tax_rate.gross_from_net(100)  # => 108.1
invoice.line_items.sum { |li| li.tax_rate.tax_amount_from_gross(li.amount) }
```

The arithmetic lives where the rate is *defined*, rather than in a separate `TaxCalculator` service that would need a long `case` statement on the rate key. Adding a new tax rate is a one-line change to the Anchormodel class, and none of the calling code has to be touched.

---

## 4. State machine with allowed transitions

When each enum entry represents a state in a workflow, Anchormodel lets you declare the allowed transitions as first-class data on each entry. The UI can then render the available next states directly, without duplicating workflow knowledge in views or controllers.

```ruby
# app/anchormodels/ticket_status.rb
class TicketStatus < Anchormodel
  attr_reader :button_label_key

  new :draft,       allowed_next: %i[open],               button_label_key: ''
  new :open,        allowed_next: %i[in_progress closed], button_label_key: N_('TicketStatus|Open|Button')
  new :in_progress, allowed_next: %i[open closed],        button_label_key: N_('TicketStatus|In progress|Button')
  new :closed,      allowed_next: %i[open],               button_label_key: N_('TicketStatus|Closed|Button')

  def allowed_next
    @allowed_next.map { |key| self.class.find(key) }
  end
end
```

```erb
<% ticket.status.allowed_next.each do |next_status| %>
  <%= button_to next_status.button_label, transition_ticket_path(ticket, to: next_status.key) %>
<% end %>
```

The view does not need to know which transitions are allowed from a given state — the Anchormodel does. When the workflow changes, you edit one file. The UI follows automatically.

---

## 5. Multi-key collection attribute

When a record can hold *many* enum values at once, Anchormodel supports storing them as a CSV string in a single column. There is no join table to maintain and no `has_and_belongs_to_many` boilerplate. You declare the attribute with `belongs_to_anchormodels` and get back a `Set` of Anchormodel instances, plus a small collection of query scopes for free.

```ruby
# app/anchormodels/feature.rb
class Feature < Anchormodel
  new :waterproof
  new :bluetooth
  new :noise_cancelling
  new :wireless_charging
  new :usb_c
end

# app/models/product.rb
class Product < ApplicationRecord
  belongs_to_anchormodels :features
end
```

```ruby
product = Product.create!(features: %i[bluetooth usb_c])
product.features                       # => #<Set: {#<Feature<bluetooth>>, #<Feature<usb_c>>}>
product.bluetooth?                     # => true
product.features << :waterproof        # mutates and persists
product.features.delete(:bluetooth)

# Bulk-key queries. (Plain `where(col: array)` is unsuitable here because the
# column stores a CSV string rather than one row per feature.)
Product.with_any_features(:waterproof, :bluetooth)   # OR semantics
Product.with_all_features(:waterproof, :bluetooth)   # AND semantics
```

The backing column is a single `string`. There is no migration to add a join table, and adding or removing a feature key never touches the schema. The trade-off is that you lose database-level referential integrity on the keys — but since the keys are defined in code rather than in data, that is exactly the right trade-off.

---

## 6. Cross-anchormodel references

Anchormodels can reference other Anchormodels in their attributes, which lets you build a small static graph of related constants. This is useful for modeling things like locales, regions, or category hierarchies.

```ruby
# app/anchormodels/country.rb
class Country < Anchormodel
  attr_reader :currency, :phone_prefix

  new :ch, currency: Currency.find('CHF'), phone_prefix: '+41'
  new :de, currency: Currency.find('EUR'), phone_prefix: '+49'
  new :fr, currency: Currency.find('EUR'), phone_prefix: '+33'
end

# app/anchormodels/locale.rb
class Locale < Anchormodel
  attr_reader :language, :country

  new :'de-ch', language: Language.find(:de), country: Country.find(:ch)
  new :'fr-ch', language: Language.find(:fr), country: Country.find(:ch)
  new :'de-de', language: Language.find(:de), country: Country.find(:de)
  new :'fr-fr', language: Language.find(:fr), country: Country.find(:fr)

  # Find all locales available in a country
  def self.in(country)
    all.select { |l| l.country == country }
  end
end
```

```ruby
user.locale.country.currency.key      # => :CHF
Locale.in(Country.find(:ch))          # => [<de-ch>, <fr-ch>]
```

Every reference is resolved at class-load time. There are no per-request database lookups, no foreign keys, and no risk of an orphaned reference at runtime.

---

## 7. Dynamic / conditional registration

The list of registered entries does not have to be hard-coded. You can register entries conditionally based on environment variables, configuration, or values read from another library at load time. This is particularly useful when different deployments of the same codebase need to expose different subsets of an enum.

```ruby
# app/anchormodels/report_template.rb
class ReportTemplate < Anchormodel
  ENABLED = ENV.fetch('REPORT_TEMPLATES', '').split(',').to_set

  def self.new_if_enabled(key, **attrs)
    return unless ENABLED.include?(key.to_s)
    new(key, **attrs)
  end

  attr_reader :layout, :template, :include_signature

  new_if_enabled :sales_quote,   layout: 'letter', template: 'sales/quote',   include_signature: false
  new_if_enabled :sales_invoice, layout: 'letter', template: 'sales/invoice', include_signature: true
  new_if_enabled :delivery_note, layout: 'letter', template: 'logistics/dn',  include_signature: true
end
```

A second variant of the pattern auto-populates its entries from another library's registry:

```ruby
# app/anchormodels/supported_locale.rb
class SupportedLocale < Anchormodel
  new :en  # make English the first entry
  I18n.available_locales.each do |locale|
    new locale.to_sym unless locale.to_sym == :en
  end
end
```

The set of valid keys reflects the reality of the current deployment, which means you never carry around dead constants for features that are disabled in this build.

---

## 8. Polymorphic class registry

When each entry maps a key to a Ruby class (along with any per-key configuration), you can use the Anchormodel as a dispatch table. Calling code looks up the entry, asks it for the class, and delegates the rest.

```ruby
# app/anchormodels/block_type.rb
class BlockType < Anchormodel
  attr_reader :component_class, :explanation_key

  new :hero,
      component_class:  Blocks::Hero,
      explanation_key:  N_('BlockType|Hero|Explanation')
  new :gallery,
      component_class:  Blocks::Gallery,
      explanation_key:  N_('BlockType|Gallery|Explanation')
  new :testimonial,
      component_class:  Blocks::Testimonial,
      explanation_key:  N_('BlockType|Testimonial|Explanation')

  def explanation
    _(@explanation_key)
  end
end
```

```ruby
def render_block(block)
  block_type = BlockType.find(block.type)
  block_type.component_class.new(block).render
end
```

Adding a new block type is a one-line addition to the Anchormodel — the dispatch site does not change. This is the open/closed principle expressed on top of plain Ruby constants.

---

## 9. Mapping external-data payloads to anchormodels

When you import data from an external API or feed, it is good practice to parse the foreign representation into Anchormodel instances right at the boundary. The rest of the application then only ever deals with strongly-typed Anchormodel objects.

```ruby
class Feature < Anchormodel
  new :elevator
  new :ramp
  new :lifting_platform
  # ... etc.

  # Translate from an upstream IDX-style feed into a list of Feature instances.
  def self.from_external_payload(payload)
    result = []
    result << find(:elevator)         if truthy?(payload[:prop_elevator])
    result << find(:ramp)             if truthy?(payload[:has_ramp])
    result << find(:lifting_platform) if truthy?(payload[:lift_platform])
    result
  end

  def self.truthy?(value)
    [1, '1', 'Y', 'y', true, 'true'].include?(value)
  end
end
```

```ruby
listing.features = Feature.from_external_payload(idx_row)
```

The translation layer lives right next to the enum it produces, so there is no `FeatureMapper` class floating around in some unrelated directory. Unknown fields in the payload simply produce no feature, rather than crashing the import.

---

## 10. Gem-internal DSL with self-registration

Anchormodel is also useful *inside* gems, as a registry that other classes populate at load time. Each subclass of a DSL base class registers an Anchormodel entry pointing back at itself, so that the rest of the gem can discover and dispatch to those subclasses without a central manifest.

```ruby
# lib/workflow/step_kind.rb
class StepKind < Anchormodel
  attr_reader :step_class, :next_step_keys

  # Steps register themselves via `WorkflowStep.inherited` (see below).
  def self.register(step_class, key:, next_step_keys: [])
    new(key, step_class: step_class, next_step_keys: next_step_keys)
  end

  def next_steps
    @next_step_keys.map { |k| self.class.find(k) }
  end
end

# lib/workflow/step.rb
class WorkflowStep
  def self.inherited(subclass)
    super
    subclass.singleton_class.attr_accessor :step_kind_key, :step_kind_next

    subclass.define_singleton_method(:register_kind) do |key:, next_keys: []|
      StepKind.register(subclass, key: key, next_step_keys: next_keys)
    end
  end
end

# config/initializers/load_workflow_steps.rb
Dir[Rails.root.join('app/workflow/**/*.rb')].each { |f| require f }

# app/workflow/steps/payment_step.rb
class PaymentStep < WorkflowStep
  register_kind key: :payment, next_keys: %i[confirmation]
  # ...
end
```

```ruby
# Anywhere in the app:
kind = StepKind.find(workflow.current_step_key)
kind.step_class.new(workflow).run

# Walk the DAG of allowed transitions:
kind.next_steps.each { |s| ... }
```

The registry is populated automatically as soon as the step classes are autoloaded. Adding a new step type is a one-file change, and there is no central manifest that needs to be updated alongside it.

---

## Mixing patterns

Real codebases tend to combine several of these patterns in a single Anchormodel. For example, a `Status` class might be ordered (`Comparable`), carry rendering behavior, declare its allowed state transitions, *and* reference another Anchormodel for related metadata. Anchormodel imposes no structure beyond the basic `new :key, **attrs` registration — what each entry holds and does is entirely up to you.
