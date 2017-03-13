--
-- Author: hxl
-- Date: 2017-03-06 14:26:39
--

local ViewBase = class("ViewBase", function()
    return display.newScene("MainScene") end )

function ViewBase:ctor(name)
    -- self:enableNodeEvents()
    self.name_ = name

    -- check CSB resource file
    local res = rawget(self.class, "RESOURCE_FILENAME")
    if res then
        self:createResoueceNode(res)
    end

    local binding = rawget(self.class, "RESOURCE_BINDING")
    if res and binding then
        self:createResoueceBinding(binding)
    end

    if self.onCreate then self:onCreate() end
end

function ViewBase:getName()
    return self.name_
end

function ViewBase:getResourceNode()
    return self.resourceNode_
end

function ViewBase:createResoueceNode(resourceFilename)
    if self.resourceNode_ then
        self.resourceNode_:removeSelf()   
        self.resourceNode_ = nil
    end
    -- self.resourceNode_ = cc.CSLoader:createNode(resourceFilename)
    self.resourceNode_ = cc.uiloader:load(resourceFilename)
    -- self.resourceNode_ =  ccs.GUIReader:getInstance():widgetFromBinaryFile(resourceFilename)
   
    assert(self.resourceNode_, string.format("ViewBase:createResoueceNode() - load resouce node from file \"%s\" failed", resourceFilename))
    self:addChild(self.resourceNode_)
end

function ViewBase:createResoueceBinding(binding)
    assert(self.resourceNode_, "ViewBase:createResoueceBinding() - not load resource node")
    for nodeName, nodeBinding in pairs(binding) do
        local node = cc.uiloader:seekNodeByName(self.resourceNode_,nodeName)
        if nodeBinding.varname then
            self[nodeBinding.varname] = node
        end
        for _, event in ipairs(nodeBinding.events or {}) do
            if event.event == "touch" then
                -- node:onTouch(handler(self, self[event.method]))
                node:onButtonClicked(handler(self,self[event.method]))
            elseif event.event == "checkBoxButton" then
            	node:onButtonStateChanged(handler(self,self[event.method]))
            end
        end
    end
end

function ViewBase:showWithScene(transition, time, more)
    self:setVisible(true)
    local scene = display.newScene(self.name_)
    scene:addChild(self)
    display.runScene(scene, transition, time, more)
    return self
end

return ViewBase
