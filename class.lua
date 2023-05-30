--
-- lua-woo - Advanced OOP features for Lua
--
-- Copyright 2020 Claudi Martinez <claudi.martinez@protonmail.com>
--
-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:
--
-- The above copyright notice and this permission notice shall be included in
-- all copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
-- THE SOFTWARE.
--

-- Access levels. Lower levels are less restrictive.
local PUBLIC                      = 0
local PROTECTED                   = 1
local PRIVATE                     = 2

-- A tag for identifying class handles
local CLASS_HANDLE_TAG            = {}

-- Keys to access to class private info
local CLASS_INNER_KEY             = {}
local CLASS_HANDLE_KEY            = {}
local CLASS_SCOPE_KEY             = {}
local CLASS_HIERARCHY_KEY         = {}
local CLASS_ANCESTORS_KEY         = {}
local CLASS_FRIENDS_KEY           = {}
local CLASS_PROTECTED_SCOPES_KEY  = {}
local CLASS_MEMBERS_KEY           = {}
local CLASS_QUALIFIED_MEMBERS_KEY = {}
local CLASS_INIT_KEY              = {}
local CLASS_UNINIT_KEY            = {}
local CLASS_DERIVE_KEY            = {}
local CLASS_CTOR_KEY              = {}


-- Keys to access to state private info
local STATE_ID_KEY           = {}
local STATE_CLASS_KEY        = {}
local STATE_PARENT_KEY       = {}

-- Special value to tag and identify state handles
local STATE_HANDLE_TAG       = {}

-- Special values to index a state's handle private properties
local HANDLE_STATE_KEY       = {}
local HANDLE_SCOPE_KEY       = {}

-- Operators that can be overloaded
local OVERLOADABLE_OPERATORS = { '__add', '__mul', '__sub', '__div', '__unm', '__pow', '__concat', '__eq', '__lt', '__le', '__tostring' }

-- Scope metatable
local SCOPE_MT               = {
    __metatable = false --Lock metatable
}

-- Create a scope
local function make_scope(owner)
    return setmetatable({ owner = owner }, SCOPE_MT)
end

-- A built-in for defining the global scope
local GLOBAL_SCOPE = make_scope()


-- Create a class member definition
-- @param class Class
-- @param name Member name
-- @param params Definition parameters
-- @return Definition
local function make_member_def(class, name, params)
    assert(type(params) == 'table', "Invalid member definition; expecting a table, but given a " .. type(params))
    local def = {
        class = class,
        name = name,
        access_level = params.private and PRIVATE or (params.protected and PROTECTED) or PUBLIC,
        read_only = params.read_only and true or false
    }

    if params.method then
        assert(type(params.method) == 'function' or (params.method == true and params.virtual), "'method' attribute must be a function or it must be pure virtual (abstract)")
        def.method = params.method

        if params.virtual then
            def.virtual = true

            if params.method == true then
                -- Pure virtual (abstract)
                def.method = function(this)
                    error(string.format("Pure virtual method '%s' of class '%s' not implemented by any derived class", name, class.name))
                end
            elseif params.final then
                def.final = true
            end
        end
    else
        assert(params.value ~= nil, string.format("missing member's initial value or method handler (member '%s')", name))
        def.value = params.value
    end

    return def
end

-- Check the access to a member
-- @param view The state view
-- @param member_name The member name
-- @param scope The access scope
-- @param write_mode If true, check access for writing
-- @return The checked member
local function check_member_access(view, member_name, scope, write_mode)
    local class = view.class

    local state_member = view.members[member_name] or error("Member '" .. tostring(member_name) .. "' not defined in class: " .. class.name)
    local member_def = state_member.def

    local access_level
    local expected_access_level = member_def.access_level

    if scope == class[CLASS_SCOPE_KEY] then
        access_level = PRIVATE
    elseif class[CLASS_PROTECTED_SCOPES_KEY][scope] then
        access_level = PROTECTED
    else
        access_level = PUBLIC
    end

    if access_level < expected_access_level then
        error(string.format("Attempting to access a %s member ('%s' in class '%s')", (expected_access_level == PROTECTED) and 'protected' or 'private', member_def.name, class.name))
    end

    if write_mode and (member_def.read_only or member_def.method) then
        error("Attempting to write to a read-only member or a method")
    end

    return state_member
end

-- Overload an operator
local function overload_operator(op, read_member)
    return function(...)
        return read_member(op)(...)
    end
end

-- Create a two-level cache
local function make_double_cache()
    local primary = {}

    return {
        get = function(self, primary_key, secondary_key)
            local secondary = primary[primary_key]

            if not secondary then
                return nil
            end

            return secondary[secondary_key]
        end,

        set = function(self, primary_key, secondary_key, value)
            local secondary = primary[primary_key]

            if not secondary then
                secondary = {}
                primary[primary_key] = secondary
            end

            secondary[secondary_key] = value
        end
    }
end

-- Create a state of the given class
local function make_state(class)
    return {
        [STATE_ID_KEY] = {},       -- Generate unique state ID
        [STATE_CLASS_KEY] = class, -- Primary class
        views = {},
        cache = make_double_cache()
    }
end

-- Create the view of a state by a class
local function make_state_view(state, class)
    local view = {
        state = state,
        class = class,
        members = {}
    }
    state.views[class] = view
    return view
end

-- Check if a state is of a given class
local function state_is_a(state, test_class)
    local primary_class = state[STATE_CLASS_KEY]
    return primary_class == test_class or (primary_class[CLASS_ANCESTORS_KEY][test_class] and true or false)
end

-- Create a state handle (aka instance reference)
-- @param state State
-- @param target_class The class for which the handle is created.
-- @param target_scope The scope used by the handle.
-- @return State handle
local function make_state_handle(state, target_class, target_scope)
    if not target_scope then
        target_scope = target_class[CLASS_SCOPE_KEY]
    end

    -- Does this handle already exist for the state?
    local cached = state.cache:get(target_class, target_scope)
    if cached then
        return cached
    end

    -- The state's primary class
    local primary_class     = state[STATE_CLASS_KEY]
    local qualified_members = primary_class[CLASS_QUALIFIED_MEMBERS_KEY]

    -- The view for the target class
    local view              = state.views[target_class]
    assert(view, "Bug!")

    -- Non-overridable, read-only fields
    local private = {
        -- Publicly accessible stuff
        __ref              = state[STATE_ID_KEY],
        __class            = primary_class[CLASS_HANDLE_KEY],
        __is_a             = function(self, test_class_handle)
            assert(getmetatable(test_class_handle) == CLASS_HANDLE_TAG, "Class argument must be a class")
            return state_is_a(state, test_class_handle[CLASS_INNER_KEY])
        end,

        -- Stuff accessible only from this script
        [HANDLE_STATE_KEY] = state,
        [HANDLE_SCOPE_KEY] = target_scope
    }

    -- Cache of accessed members
    local cached_accessed_read_members = {}
    local cached_accessed_write_members = {}
    local cached_accessed_qualified_members = {}

    -- Function to read a member
    local read_member = function(member_name)
        local state_member = cached_accessed_read_members[member_name]
        if not state_member then
            state_member = check_member_access(view, member_name, target_scope, false)
            cached_accessed_read_members[member_name] = state_member
        end
        return state_member.data
    end

    local MT = {
        __index = function(t, key)
            -- Requesting private data?
            local private_data = private[key]
            if private_data then
                return private_data
            end

            -- Requesting a qualified member?
            local qclass = qualified_members[key]
            if qclass then
                local qm = cached_accessed_qualified_members[qclass]

                if not qm then
                    qm = make_state_handle(state, qclass, target_scope)
                    cached_accessed_qualified_members[qclass] = qm
                end

                return qm
            end

            -- Reading normal member
            return read_member(key)
        end,

        __newindex = function(t, key, value)
            if private[key] or qualified_members[key] then
                error("Attempting to write to a built-in symbol")
            end

            assert(value ~= nil, "cannot set nil value to instance's properties")

            -- Writing normal member
            local state_member = cached_accessed_write_members[key]
            if not state_member then
                state_member = check_member_access(view, key, target_scope, true)
                cached_accessed_write_members[key] = state_member
            end
            state_member.data = value
        end,

        __eq = function(a, b) -- This might be overridden by operator overload (see below)
            return a[STATE_ID_KEY] == b[STATE_ID_KEY]
        end,

        __metatable = STATE_HANDLE_TAG -- Identify the interface and lock this metatable
    }

    -- Operator overload
    for _, op in ipairs(OVERLOADABLE_OPERATORS) do
        MT[op] = overload_operator(op, read_member)
    end

    -- Create handle and cache it.
    local handle = setmetatable({}, MT)

    state.cache:set(target_class, target_scope, handle)

    return handle
end

-- Cast a state handle to another class
local function cast_state_handle(handle, target_class)
    return make_state_handle(handle[HANDLE_STATE_KEY], target_class, handle[HANDLE_SCOPE_KEY])
end

-- Create a state handle using a different scope
local function rescope_state_handle(handle, scope)
    local state = handle[HANDLE_STATE_KEY]
    return make_state_handle(state, state[STATE_CLASS_KEY], scope)
end

-- Create a method caller
local function make_method_caller(class, method)
    return function(instance, ...)
        assert(getmetatable(instance) == STATE_HANDLE_TAG, "Wrong call to method. Methods should be called using ':'")
        local this = make_state_handle(instance[HANDLE_STATE_KEY], class)
        local method_args = {}

        for iarg = 1, select("#", ...) do
            local arg = select(iarg, ...)

            if getmetatable(arg) == STATE_HANDLE_TAG then
                -- It's a state handle: re-scope it in "this" scope				
                table.insert(method_args, rescope_state_handle(arg, this[HANDLE_SCOPE_KEY]))
            else
                table.insert(method_args, arg)
            end
        end

        return method(this, table.unpack(method_args))
    end
end

-- Create a state member
local function make_state_member(member_def)
    local data

    if member_def.method then
        -- It's a method
        data = make_method_caller(member_def.class, member_def.method)
    else
        -- It's a property
        data = member_def.value
    end

    return {
        def = member_def,
        data = data
    }
end

-- Override a state view member
local function override_view_member(view_members, member_name, new_member)
    local current_member = view_members[member_name]

    if current_member then
        -- View already has the member

        -- Fetch member definition
        local def = current_member.def

        if def.method then
            -- Member is a method
            if def.virtual then
                -- Virtual method
                if def.final then
                    error(string.format("cannot override final virtual method '%s' of class '%s'", member_name, def.class.name))
                end

                -- Virtual override				
                current_member.def  = new_member.def
                current_member.data = new_member.data
                return
            end
        end
    end

    -- Normal override
    view_members[member_name] = new_member
end

-- Create an instance of a class
function new(__class, ...)
    assert(getmetatable(__class) == CLASS_HANDLE_TAG, "Argument 1 must be a class")

    -- The __class argument is a wrapper (handle) of the actual class
    local class = __class[CLASS_INNER_KEY]

    -- Fetch class hierarchy
    local hierarchy = class[CLASS_HIERARCHY_KEY]

    local instance_state = make_state(class)

    -- Set metatable for capturing garbage collection action and call destructors
    setmetatable(instance_state, {
        __gc = function(t)
            for i = #hierarchy, 1, -1 do
                hierarchy[i][CLASS_UNINIT_KEY](instance_state)
            end
        end,
        __metatable = false --Lock metatable
    })

    -- Init		
    for _, hierarchy_class in ipairs(hierarchy) do
        hierarchy_class[CLASS_INIT_KEY](instance_state)
    end

    -- Call constructor
    local this = make_state_handle(instance_state, class)
    class[CLASS_CTOR_KEY](this, ...)

    return make_state_handle(instance_state, class, GLOBAL_SCOPE)
end

-- Cast an instance to a given class, if possible.
function cast(instance, __class)
    assert(getmetatable(instance) == STATE_HANDLE_TAG, "First argument must be an instance")
    assert(getmetatable(__class) == CLASS_HANDLE_TAG, "Second argument must be a class")
    return cast_state_handle(instance, __class[CLASS_INNER_KEY])
end

-- Check if the given argument is an instance of a class.
-- @param instance Object to test
-- @param __class If not nil, test if the instance is of the given class.
-- @param strict If true, class test is done in a strict manner.
function is_object(instance, __class, strict)
    if getmetatable(instance) == STATE_HANDLE_TAG then
        if __class then
            assert(getmetatable(__class) == CLASS_HANDLE_TAG, "Class argument must be a class")

            if strict then
                return instance.__class == __class
            end

            return state_is_a(instance[HANDLE_STATE_KEY], __class[CLASS_INNER_KEY])
        end
        return true
    end
    return false
end

-- Check if the given argument is a class
function is_class(__class)
    return getmetatable(__class) == CLASS_HANDLE_TAG
end

-- Access an instance as a friend
function friend(instance, key)
    assert(getmetatable(instance) == STATE_HANDLE_TAG, "First argument must be an instance")
    local state = instance[HANDLE_STATE_KEY]
    local class = state[STATE_CLASS_KEY]

    if class[CLASS_FRIENDS_KEY][key] then
        return make_state_handle(state, class)
    end

    error("Not a friend of class " .. class.name)
end

-- Create a class
function class(class_name, __parent, class_attrs)
    -- The __parent argument is a wrapper (handle) of the actual parent class
    local parent
    if __parent then
        assert(getmetatable(__parent) == CLASS_HANDLE_TAG, "Parent argument must be a class")
        parent = __parent[CLASS_INNER_KEY]
    end


    -- Default class attributes
    class_attrs = class_attrs or {
        final = false
    }

    -- Setup friends
    local friends = {}
    if class_attrs.friends then
        if type(class_attrs.friends) == 'table' then
            for _, friend in ipairs(class_attrs.friends) do
                friends[friend] = true
            end
        else
            error("Invalid friends attribute")
        end
    end

    -- Handle to this class. It is a wrapper of the class, and at the end of the class
    -- initialization is protected with a metatable.
    local this_class_handle         = {}

    -- Basic initialization	
    local this_class                = {
        name                          = class_name,
        parent                        = parent,

        -- Private fields					
        [CLASS_MEMBERS_KEY]           = {},
        [CLASS_QUALIFIED_MEMBERS_KEY] = {},      -- A collection of names of qualified members (keys are ancestor class names and values are the corresponding class)
        [CLASS_PROTECTED_SCOPES_KEY]  = {},      -- Allowed scopes for accessing to protected members. Keys are class scopes, values are just "true"
        [CLASS_FRIENDS_KEY]           = friends, -- Hash of friends. Keys are friend secret keys, and values are "true"  (See function friend())
        [CLASS_ANCESTORS_KEY]         = {}       -- Hash of ancestors. Keys are ancestor classes and values are "true"
    }

    -- Scope
    this_class[CLASS_SCOPE_KEY]     = make_scope(this_class)

    -- Reflection
    this_class[CLASS_INNER_KEY]     = this_class
    this_class[CLASS_HANDLE_KEY]    = this_class_handle

    -- Init hierarchy
    this_class[CLASS_HIERARCHY_KEY] = { this_class }

    -- Fetch members	
    local members                   = this_class[CLASS_MEMBERS_KEY]

    this_class[CLASS_INIT_KEY]      = function(state)
        -- My view of the state
        local view = make_state_view(state, this_class)
        local view_members = view.members

        -- Inherit parent view
        if parent then
            local parent_view = state.views[parent]
            for name, state_member in pairs(parent_view.members) do
                view_members[name] = state_member
            end
        end

        -- Override with own members
        for name, member_def in pairs(members) do
            override_view_member(view_members, name, make_state_member(member_def))
        end
    end

    this_class[CLASS_CTOR_KEY]      = function(this, ...)
        local ctor = class_attrs.ctor
        local state = this[HANDLE_STATE_KEY]

        local parent_ctor_called_by_user = false

        if ctor then
            -- User constructor is defined
            -- Create a function that can be called from the user's constructor to explicitly invoke the parent's constructor
            local call_parent_ctor = function(...)
                if parent then
                    parent[CLASS_CTOR_KEY](this, ...)
                end
                parent_ctor_called_by_user = true
            end

            -- Invoke constructor
            local ctor_caller = make_method_caller(this_class, ctor)
            ctor_caller(this, call_parent_ctor, ...)
        end


        -- Call parent's constructor unless the user called it.
        if parent and not parent_ctor_called_by_user then
            parent[CLASS_CTOR_KEY](this, ...)
        end
    end

    this_class[CLASS_UNINIT_KEY]    = function(state)
        local dtor = class_attrs.dtor

        if dtor then
            local this = make_state_handle(state, this_class)
            dtor(this)
        end
    end

    this_class[CLASS_DERIVE_KEY]    = function(child_class)
        assert(not class_attrs.final, "cannot derive from the final class: " .. class_name)

        local child_class_scope = child_class[CLASS_SCOPE_KEY]
        local child_hierarchy = child_class[CLASS_HIERARCHY_KEY]
        local child_ancestors = child_class[CLASS_ANCESTORS_KEY]
        local child_qualified_members = child_class[CLASS_QUALIFIED_MEMBERS_KEY]

        this_class[CLASS_PROTECTED_SCOPES_KEY][child_class_scope] = true

        table.insert(child_hierarchy, 1, this_class)

        child_ancestors[this_class] = true

        child_qualified_members[class_name] = this_class


        if parent then
            parent[CLASS_DERIVE_KEY](child_class)
        end
    end

    local check_its_me              = function(self)
        assert(self == this_class, "First argument must be the class: " .. class_name)
    end

    this_class.define_member        = function(self, name, params)
        check_its_me(self)
        if members[name] then
            error(string.format("Member '%s' already defined in class '%s'", name, class_name))
        end
        members[name] = make_member_def(this_class, name, params)
    end

    -- Inherit from parent class, if any.
    if parent then
        parent[CLASS_DERIVE_KEY](this_class)
    end

    -- Create initial members
    if type(class_attrs.members) == 'table' then
        for name, params in pairs(class_attrs.members) do
            this_class:define_member(name, params)
        end
    end

    -- Protect and return the handle for the class
    return setmetatable(this_class_handle, {
        __index = this_class,
        __newindex = function(t, k, v)
            error("Cannot change class properties")
        end,
        __metatable = CLASS_HANDLE_TAG -- Lock metatable
    })
end
