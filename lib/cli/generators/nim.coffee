#!/usr/bin/env coffee
###
 * bosco code generation
 *
 * Generate Nim stubs for
 * use by bosco.ECS
 *
###
fs = require('fs')
path = require('path')
mkdirp = require('mkdirp')
config = require("#{process.cwd()}/bosco.json")


params = (a, sep = ', ') ->
  b = []
  for item in a
    b.push item.split(':')[0]
  return b.join(sep)

args = (a, sep = ', ') ->
  b = []
  for item in a
    b.push item
  return b.join(sep)

  
module.exports =
#
# generate entity extensions
#
# @return none
#
  run: (flags...) ->

    #if flags.indexOf('-u') or flags.indexOf('--unity')

    s0 = [] # Components.nim
    se = [] # Entity.nim
    st = [] # Pool type variables
    sc = [] # Pool constructor
    s2 = [] # Match.nim
    sm = [] # variables
    s3 = [] # World.nim


    s0.push "##"
    s0.push "## Entitas Generated Components for #{config.namespace}"
    s0.push "##"
    s0.push "## ** do not edit this file **" 
    s0.push "##"
    s0.push "import queues"
    s0.push "import bosco/ecs"
    s0.push "import bosco/Sprite"
    s0.push "const POOL_SIZE : int = #{config.alloc.components}"
    s0.push ""
    s0.push "##"
    s0.push "## Define Components"
    s0.push "##"
    s0.push "type"
    
    se.push "##"
    se.push "## Entitas Generated Entity Extensions for #{config.namespace}"
    se.push "##"
    se.push "## ** do not edit this file **"
    se.push "##"
    se.push "import queues"
    se.push "import bosco/ecs"
    se.push "import bosco/Sprite"
    se.push "import ComponentEx"
    se.push ""
    se.push "##"
    se.push "## Extend Entity"
    se.push "##"

    s2.push "##"
    s2.push "## Entitas Generated Match Extensions for #{config.namespace}"
    s2.push "##"
    s2.push "## ** do not edit this file **"
    s2.push "##"
    s2.push "import bosco/ecs"
    s2.push "import ComponentEx"
    s2.push "##"
    s2.push "## Define a Match for each Component"
    s2.push "##"
    s2.push "type MatchObj = ref object of RootObj"

    s3.push "##"
    s3.push "## Entitas Generated World Extensions for #{config.namespace}"
    s3.push "##"
    s3.push "## ** do not edit this file **"
    s3.push "##"
    s3.push "import bosco/ecs"
    s3.push "import ComponentEx"
    s3.push "import MatchEx"
    s3.push "import EntityEx"
    s3.push ""
    s3.push "##"
    s3.push "## Extend World"
    s3.push "##"

    ###
     * Components Enum
    ###
    s0.push "  Component* {.pure.} = enum"
    for Name, properties of config.components
      s0.push "    #{Name}"
    s0.push ""

    ###
     * Components Type Definitions
    ###
    for Name, properties of config.components
      name = Name[0].toLowerCase()+Name[1...]
      s0.push "  #{Name}Component* = ref object of IComponent"
      if properties is false
        s0.push "    #{name}* : bool"
      else
        for p in properties
          s0.push "    #{p.replace(':', '* : ')}"
      s0.push ""
    s0.push ""

    ###
     * Extend Entity with components
    ###
    se.push ""
    for Name, properties of config.components
      name = Name[0].toLowerCase()+Name[1...]
      switch properties
        when false
          st.push "    #{name}Component* : #{Name}Component"
          sc.push ""
          sc.push "  result.#{name}Component = #{Name}Component()"
          se.push "## @type {boolean} "
          se.push "proc is#{Name}*(this : Entity) : bool ="
          se.push "  this.hasComponent(int(Component.#{Name}))"
          se.push "proc `is#{Name}=`*(this : Entity, value : bool) ="
          se.push "  if value != this.is#{Name}:"
          se.push "    if value:"
          se.push "      discard this.addComponent(int(Component.#{Name}), Pool.#{name}Component)"
          se.push "    else:"
          se.push "      discard this.removeComponent(int(Component.#{Name}))"
          se.push ""
          se.push "##"
          se.push "## @param {boolean} value"
          se.push "## @returns {bosco.Entity}"
          se.push "##"
          se.push "proc set#{Name}*(this : Entity, value : bool) : Entity ="
          se.push "  this.is#{Name} = value"
          se.push "  return this"
          se.push ""

        else
          st.push "    #{name}Component* : Queue[#{Name}Component]"
          se.push ""
          
          sc.push ""
          sc.push "  result.#{name}Component = initQueue[#{Name}Component]()"
          sc.push "  for i in 1..POOL_SIZE:"
          sc.push "    result.#{name}Component.add(#{Name}Component())"
          
          se.push "proc clear#{Name}Component*(this : Entity) ="
          se.push "  Pool.#{name}Component = initQueue[#{Name}Component]()"
          se.push ""
          se.push "## @type {#{config.namespace}.#{Name}Component} "
          se.push "proc #{name}*(this : Entity) : #{Name}Component ="
          se.push "  (#{Name}Component)this.getComponent(int(Component.#{Name}))"
          se.push ""
          se.push "## @type {boolean} "
          se.push "proc has#{Name}*(this : Entity) : bool ="
          se.push "  this.hasComponent(int(Component.#{Name}))"
          se.push ""
          se.push "##"
          for p in properties
            se.push "## @param {#{p.split(':')[1]}} #{p.split(':')[0]}"
          se.push "## @returns {bosco.Entity}"
          se.push "##"
          se.push "proc add#{Name}*(this : Entity, #{properties.join(', ')}) : Entity ="
          se.push "  var component = if Pool.#{name}Component.len > 0 : Pool.#{name}Component.dequeue() else: #{Name}Component()"
          for p in properties
            se.push "  component.#{p.split(':')[0]} = #{p.split(':')[0]}"
          se.push "  discard this.addComponent(int(Component.#{Name}), component)"
          se.push "  return this"
          se.push ""
          se.push "##"
          for p in properties
            se.push "## @param {#{p.split(':')[1]}} #{p.split(':')[0]}"
          se.push "## @returns {bosco.Entity}"
          se.push "##"
          se.push "proc replace#{Name}*(this : Entity, #{properties.join(', ')}) : Entity ="
          se.push "  var previousComponent = if this.has#{Name} : this.#{name} else: nil"
          se.push "  var component = if Pool.#{name}Component.len > 0 : Pool.#{name}Component.dequeue() else: #{Name}Component()"
          for p in properties
            se.push "  component.#{p.split(':')[0]} = #{p.split(':')[0]}"
          se.push "  discard this.replaceComponent(int(Component.#{Name}), component)"
          se.push "  if previousComponent != nil:"
          se.push "    Pool.#{name}Component.enqueue(previousComponent)"
          se.push ""
          se.push "  return this"
          se.push ""
          se.push "##"
          se.push "## @returns {bosco.Entity}"
          se.push "##"
          se.push "proc remove#{Name}*(this : Entity) : Entity ="
          se.push "  var component = this.#{name}"
          se.push "  discard this.removeComponent(int(Component.#{Name}))"
          se.push "  Pool.#{name}Component.enqueue(component)"
          se.push "  return this"
          se.push ""


    ###
     * Matchers
    ###
    for Name, properties of config.components
      name = Name[0].toLowerCase()+Name[1...];
      s2.push "  match#{Name} : Matcher"
      
      sm.push ""
      sm.push "proc #{Name}*(this : MatchObj) : Matcher ="
      sm.push "  if this.match#{Name} == nil:"
      sm.push "    this.match#{Name} = MatchAllOf(@[int(Component.#{Name})])"
      sm.push "  return this.match#{Name}"


    
    for Name, pooled of config.entities
      if pooled
        name = Name[0].toLowerCase()+Name[1...];
        properties = config.components[Name]
        if config.components[Name] is false
          s3.push "## @type {bosco.Match} "
          s3.push "proc #{name}Entity*(this : World) : Entity ="
          s3.push "  return this.getGroup(Match.#{Name}).getSingleEntity()"
          s3.push ""
          s3.push "## @type {boolean} "
          s3.push "proc is#{Name}*(this : World) : bool ="
          s3.push "  return this.#{name}Entity != nil"
          s3.push "proc `is#{Name}=`*(this : World, value : bool) ="
          s3.push "  var entity = this.#{name}Entity"
          s3.push "  if value != (entity != nil):"
          s3.push "    if value:"
          s3.push "      this.createEntity(\"#{Name}\").is#{Name} = true"
          s3.push "    else:"
          s3.push "      this.destroyEntity(entity)"
          s3.push ""


        else
          s3.push "## @type {bosco.Entity} "
          s3.push "proc #{name}Entity*(this : World) : Entity ="
          s3.push "  return this.getGroup(Match.#{Name}).getSingleEntity()"
          s3.push ""
          s3.push "## @type {#{config.namespace}.#{Name}Component} "
          s3.push "proc #{name}*(this : World) : #{Name}Component ="
          s3.push "  return this.#{name}Entity.#{name}"
          s3.push ""
          s3.push "## @type {boolean} "
          s3.push "proc has#{Name}*(this : World) : bool ="
          s3.push "  return this.#{name}Entity != nil"
          s3.push ""
          s3.push "##"
          for p in properties
            s3.push "## @param {#{p.split(':')[1]}} #{p.split(':')[0]}"
          s3.push "## @returns {bosco.Entity}"
          s3.push "##"
          s3.push "proc set#{Name}*(this : World, #{properties.join(', ')}) : Entity ="
          s3.push "  if this.has#{Name}:"
          s3.push "    raise newException(OSError, \"SingleEntityException Matching #{Name}\")"
          s3.push ""
          s3.push "  var entity = this.createEntity(\"#{Name}\")"
          s3.push "  discard entity.add#{Name}(#{params(properties)})"
          s3.push "  return entity"
          s3.push ""
          s3.push "##"
          for p in properties
            s3.push "## @param {#{p.split(':')[1]}} #{p.split(':')[0]}"
          s3.push "## @returns {bosco.Entity}"
          s3.push "##"
          s3.push "proc replace#{Name}*(this : World, #{properties.join(', ')}) : Entity ="
          s3.push "  var entity = this.#{name}Entity"
          s3.push "  if entity == nil:"
          s3.push "    entity = this.set#{Name}(#{params(properties)})"
          s3.push "  else:"
          s3.push "     discard entity.replace#{Name}(#{params(properties)})"
          s3.push "  return entity"
          s3.push ""
          s3.push "##"
          s3.push "## @returns {bosco.Entity}"
          s3.push "##"
          s3.push "proc remove#{Name}*(this : World) ="
          s3.push "  this.destroyEntity(this.#{name}Entity)"
          s3.push ""


          
    s0.push "  ##"
    s0.push "  ## Component Pool"
    s0.push "  ##"
    s0.push "  PoolObj = ref object of RootObj"
    s0.push st.join('\n')
    s0.push ""
    s0.push "##"
    s0.push "## constructor for a new Component Pool"
    s0.push "##"
    s0.push "proc newPoolObj() : PoolObj ="
    s0.push "  new(result)"
    s0.push sc.join('\n')
    s0.push ""
    s0.push "var Pool* = newPoolObj()"
    
    s2.push sm.join('\n')
    s2.push ""
    s2.push "var Match* = MatchObj()"

    mkdirp.sync path.join(process.cwd(), 'gen/')
    
    s0.push('\n')
    se.push('\n')
    s2.push('\n')
    s3.push('\n')
    
    fs.writeFileSync(path.join(process.cwd(), "src/gen/ComponentEx.nim"), s0.join('\n'))
    fs.writeFileSync(path.join(process.cwd(), "src/gen/EntityEx.nim"), se.join('\n'))
    fs.writeFileSync(path.join(process.cwd(), "src/gen/MatchEx.nim"), s2.join('\n'))
    fs.writeFileSync(path.join(process.cwd(), "src/gen/WorldEx.nim"), s3.join('\n'))

