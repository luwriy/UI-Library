-- Part 1: Library Initialization and Variables
local Library = {
    Version = "1.0.0",
    Unloaded = false,
    Options = {},
    Themes = {
        Dark = {
            Primary = Color3.fromRGB(32, 32, 32),
            Secondary = Color3.fromRGB(45, 45, 45),
            Tertiary = Color3.fromRGB(60, 60, 60),
            Text = Color3.fromRGB(240, 240, 240),
            TextDark = Color3.fromRGB(180, 180, 180),
            Accent = Color3.fromRGB(96, 205, 255),
            AccentDark = Color3.fromRGB(76, 180, 230)
        },
        Light = {
            Primary = Color3.fromRGB(240, 240, 240),
            Secondary = Color3.fromRGB(220, 220, 220),
            Tertiary = Color3.fromRGB(200, 200, 200),
            Text = Color3.fromRGB(32, 32, 32),
            TextDark = Color3.fromRGB(70, 70, 70),
            Accent = Color3.fromRGB(76, 180, 230),
            AccentDark = Color3.fromRGB(56, 160, 210)
        }
    }
}

local Icons = {
    settings = "rbxassetid://10723407389",
    close = "rbxassetid://10723407085",
    minimize = "rbxassetid://10723406885",
    restore = "rbxassetid://10723406783",
    check = "rbxassetid://10723368542",
    dropdown = "rbxassetid://10723368866",
    colorpicker = "rbxassetid://10723368996",
    slider = "rbxassetid://10723368203",
    search = "rbxassetid://10723406597",
    refresh = "rbxassetid://10723406416",
    folder = "rbxassetid://10723405948",
    alert = "rbxassetid://10723369915"
}

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local TextService = game:GetService("TextService")

local Player = Players.LocalPlayer
local Mouse = Player:GetMouse()
local Viewport = workspace.CurrentCamera.ViewportSize
local TweenInfoHover = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local TweenInfoClick = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local TweenInfoNotification = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

-- Part 2: Utility Functions
local function createInstance(instanceType, properties)
    if not instanceType or type(instanceType) ~= "string" then
        warn("Invalid instanceType provided to createInstance.")
        return nil
    end
    local instance = Instance.new(instanceType)
    if properties and type(properties) == "table" then
        for property, value in pairs(properties) do
            if property ~= "Parent" then
                if instance[property] ~= nil then
                    instance[property] = value
                else
                    warn("Property '" .. property .. "' does not exist on instance of type '" .. instanceType .. "'.")
                end
            end
        end
        if properties.Parent then
            instance.Parent = properties.Parent
        end
    end
    return instance
end

local function createTween(object, info, properties)
    local tween = TweenService:Create(object, info, properties)
    tween:Play()
    return tween
end

local function roundNumber(number, decimalPlaces)
    local factor = 10 ^ (decimalPlaces or 0)
    return math.floor(number * factor + 0.5) / factor
end

local function shadowEffect(object, size, transparency)
    local shadow = createInstance("ImageLabel", {
        Name = "Shadow",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, size * 2, 1, size * 2),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Image = "rbxassetid://7896079142",
        ImageColor3 = Color3.fromRGB(0, 0, 0),
        ImageTransparency = transparency or 0.5,
        ScaleType = Enum.ScaleType.Slice,
        SliceCenter = Rect.new(25, 25, 26, 26),
        Parent = object
    })
    return shadow
end

-- Part 3: UI Effects
local function applyHoverEffect(object, defaultColor, hoverColor, textObject, defaultTextColor, hoverTextColor)
    object.MouseEnter:Connect(function()
        createTween(object, TweenInfoHover, { BackgroundColor3 = hoverColor })
        if textObject then
            createTween(textObject, TweenInfoHover, { TextColor3 = hoverTextColor })
        end
    end)
    object.MouseLeave:Connect(function()
        createTween(object, TweenInfoHover, { BackgroundColor3 = defaultColor })
        if textObject then
            createTween(textObject, TweenInfoHover, { TextColor3 = defaultTextColor })
        end
    end)
end

local function applyClickEffect(object, defaultColor, clickColor, callback)
    object.MouseButton1Down:Connect(function()
        createTween(object, TweenInfoClick, { BackgroundColor3 = clickColor })
    end)
    object.MouseButton1Up:Connect(function()
        createTween(object, TweenInfoClick, { BackgroundColor3 = defaultColor })
    end)
    object.MouseButton1Click:Connect(function()
        if callback then callback() end
    end)
end

local function toggleElement(element, contentLayout, defaultSize, expandedSize, arrowObject)
    local opened = false
    return function()
        opened = not opened
        if opened then
            createTween(element, TweenInfoNotification, { Size = expandedSize })
            if arrowObject then
                createTween(arrowObject, TweenInfoNotification, { Rotation = 180 })
            end
        else
            createTween(element, TweenInfoNotification, { Size = defaultSize })
            if arrowObject then
                createTween(arrowObject, TweenInfoNotification, { Rotation = 0 })
            end
        end
    end
end

local function updateSliderValue(sliderBack, sliderFill, sliderDot, min, max, value, callback)
    local percent = (value - min) / (max - min)
    sliderFill.Size = UDim2.new(percent, 0, 1, 0)
    sliderDot.Position = UDim2.new(percent, 0, 0.5, -6)
    if callback then callback(value) end
end

local function selectTab(tabName, window, currentTheme)
    if window.ActiveTab then
        local activeTab = window.Tabs[window.ActiveTab]
        activeTab.Content.Visible = false
        createTween(activeTab.Button, TweenInfoHover, { BackgroundColor3 = currentTheme.Secondary })
        if activeTab.Icon then
            createTween(activeTab.Icon, TweenInfoHover, { ImageColor3 = currentTheme.TextDark })
        end
        createTween(activeTab.Title, TweenInfoHover, { TextColor3 = currentTheme.TextDark })
    end
    local newTab = window.Tabs[tabName]
    newTab.Content.Visible = true
    createTween(newTab.Button, TweenInfoHover, { BackgroundColor3 = currentTheme.Accent })
    if newTab.Icon then
        createTween(newTab.Icon, TweenInfoHover, { ImageColor3 = currentTheme.Text })
    end
    createTween(newTab.Title, TweenInfoHover, { TextColor3 = currentTheme.Text })
    window.ActiveTab = tabName
end

-- Part 4: Dialog Constructor
function Library:Dialog(options)
    options = options or {}
    options.Title = options.Title or "Dialog"
    options.Content = options.Content or "This is a dialog box."
    options.Buttons = options.Buttons or { { Title = "OK", Callback = function() end } }
    local dialogGui = createInstance("ScreenGui", { Name = "DialogGui", Parent = CoreGui, ZIndexBehavior = Enum.ZIndexBehavior.Sibling })
    local dialogFrame = createInstance("Frame", {
        Name = "DialogFrame",
        BackgroundColor3 = Library.CurrentTheme.Primary,
        BorderSizePixel = 0,
        Position = UDim2.new(0.5, 0, 0.5, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Size = UDim2.new(0, 400, 0, 200),
        Parent = dialogGui
    })
    shadowEffect(dialogFrame, 15, 0.3)
    createInstance("UICorner", { CornerRadius = UDim.new(0, 8), Parent = dialogFrame })
    createInstance("TextLabel", {
        Name = "DialogTitle",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -20, 0, 40),
        Position = UDim2.new(0, 10, 0, 5),
        Text = options.Title,
            TextColor3 = Library.CurrentTheme.TextDark,
            TextSize = 13,
            TextWrapped = true,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Top,
            Font = Enum.Font.Gotham,
            TextTransparency = 0.3,
            Parent = notification
        })
    end
    createTween(notification, TweenInfoNotification, { Position = UDim2.new(0, 0, 0, 0) })
    if options.Duration then
        task.spawn(function()
            task.wait(options.Duration)
            if notification and notification.Parent then
                createTween(notification, TweenInfoNotification, { Position = UDim2.new(1, 0, 0, 0) }).Completed:Connect(function()
                    notification:Destroy()
                end)
            end
        end)
    end
    return notification
end

-- Part 6: Window Constructor - Initialization
function Library:CreateWindow(options)
    options = options or {}
    options.Title = options.Title or "FluentUI"
    options.SubTitle = options.SubTitle or "by ItsYourDev"
    options.TabWidth = options.TabWidth or 160
    options.Size = options.Size or UDim2.fromOffset(580, 460)
    options.Acrylic = options.Acrylic ~= nil and options.Acrylic or true
    options.Theme = options.Theme or "Dark"
    options.MinimizeKey = options.MinimizeKey or Enum.KeyCode.RightControl
    local window = { Tabs = {}, ActiveTab = nil, TabCount = 0 }
    Library.CurrentTheme = Library.Themes[options.Theme]
    local mainGui = createInstance("ScreenGui", {
        Name = "FluentUI",
        Parent = CoreGui,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        ResetOnSpawn = false
    })
    local mainFrame = createInstance("Frame", {
        Name = "MainFrame",
        BackgroundColor3 = Library.CurrentTheme.Primary,
        BorderSizePixel = 0,
        Position = UDim2.new(0.5, 0, 0.5, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Size = options.Size,
        Parent = mainGui
    })
    shadowEffect(mainFrame, 15, 0.5)
    if options.Acrylic then
        local blur = createInstance("Frame", {
            Name = "AcrylicBlur",
            BackgroundTransparency = 0.85,
            BackgroundColor3 = Library.CurrentTheme.Primary,
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 1, 0),
            ZIndex = 0,
            Parent = mainFrame
        })
        createInstance("BlurEffect", { Name = "Blur", Size = 6, Parent = blur })
    end
    createInstance("UICorner", { CornerRadius = UDim.new(0, 8), Parent = mainFrame })
    local topBar = createInstance("Frame", {
        Name = "TopBar",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 30),
        Parent = mainFrame
    })
    local title = createInstance("TextLabel", {
        Name = "Title",
        BackgroundTransparency = 1,
        Size = UDim2.new(0, 200, 1, 0),
        Position = UDim2.new(0, 15, 0, 0),
        Text = options.Title,
        TextColor3 = Library.CurrentTheme.Text,
        TextSize = 18,
        TextXAlignment = Enum.TextXAlignment.Left,
        Font = Enum.Font.GothamBold,
        Parent = topBar
    })
    if not title then
        warn("Failed to create Title object. Check the createInstance function.")
        return
    end
    local titleTextSize = TextService:GetTextSize(options.Title, title.TextSize, title.Font, Vector2.new(1000, 1000))
    local subTitle = createInstance("TextLabel", {
        Name = "SubTitle",
        BackgroundTransparency = 1,
        Size = UDim2.new(0, 200, 1, 0),
        Position = UDim2.new(0, 15 + titleTextSize.X + 10, 0, 0),
        Text = options.SubTitle,
        TextColor3 = Library.CurrentTheme.TextDark,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        Font = Enum.Font.Gotham,
        Parent = topBar
    })
    local controlButtons = createInstance("Frame", {
        Name = "ControlButtons",
        BackgroundTransparency = 1,
        Size = UDim2.new(0, 60, 1, 0),
        Position = UDim2.new(1, -65, 0, 0),
        Parent = topBar
    })
    local minimizeButton = createInstance("ImageButton", {
        Name = "MinimizeButton",
        BackgroundTransparency = 1,
        Size = UDim2.new(0, 20, 0, 20),
        Position = UDim2.new(0, 5, 0, 5),
        Image = Icons.minimize,
        ImageColor3 = Library.CurrentTheme.TextDark,
        Parent = controlButtons
    })
    local closeButton = createInstance("ImageButton", {
        Name = "CloseButton",
        BackgroundTransparency = 1,
        Size = UDim2.new(0, 20, 0, 20),
        Position = UDim2.new(0, 35, 0, 5),
        Image = Icons.close,
        ImageColor3 = Library.CurrentTheme.TextDark,
        Parent = controlButtons
    })
    local dragging = false
    local dragInput
    local dragStart
    local startPos
    local function updateDrag(input)
        local delta = input.Position - dragStart
        mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
    topBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = mainFrame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    topBar.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            dragInput = input
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            updateDrag(input)
        end
    end)
    local minimized = false
    local minimizeSize = UDim2.new(1, 0, 0, 30)
    local originalSize = options.Size
    minimizeButton.MouseButton1Click:Connect(function()
        minimized = not minimized
        if minimized then
            minimizeButton.Image = Icons.restore
            createTween(mainFrame, TweenInfoNotification, { Size = minimizeSize })
        else
            minimizeButton.Image = Icons.minimize
            createTween(mainFrame, TweenInfoNotification, { Size = originalSize })
        end
    end)
    minimizeButton.MouseEnter:Connect(function()
        createTween(minimizeButton, TweenInfoHover, { ImageColor3 = Library.CurrentTheme.Text })
    end)
    minimizeButton.MouseLeave:Connect(function()
        createTween(minimizeButton, TweenInfoHover, { ImageColor3 = Library.CurrentTheme.TextDark })
    end)
    closeButton.MouseButton1Click:Connect(function()
        createTween(mainGui, TweenInfoNotification, { Position = UDim2.new(1, 0, 0, 0) }).Completed:Connect(function()
            mainGui:Destroy()
            Library.Unloaded = true
        end)
    end)
    closeButton.MouseEnter:Connect(function()
        createTween(closeButton, TweenInfoHover, { ImageColor3 = Color3.fromRGB(255, 100, 100) })
    end)
    closeButton.MouseLeave:Connect(function()
        createTween(closeButton, TweenInfoHover, { ImageColor3 = Library.CurrentTheme.TextDark })
    end)
    UserInputService.InputBegan:Connect(function(input, processed)
        if not processed and input.KeyCode == options.MinimizeKey then
            minimized = not minimized
            if minimized then
                minimizeButton.Image = Icons.restore
                createTween(mainFrame, TweenInfoNotification, { Size = minimizeSize })
            else
                minimizeButton.Image = Icons.minimize
                createTween(mainFrame, TweenInfoNotification, { Size = originalSize })
            end
        end
    end)
    local tabContainer = createInstance("Frame", {
        Name = "TabContainer",
        BackgroundColor3 = Library.CurrentTheme.Secondary,
        BorderSizePixel = 0,
        Size = UDim2.new(0, options.TabWidth, 1, -30),
        Position = UDim2.new(0, 0, 0, 30),
        Parent = mainFrame
    })
    createInstance("UICorner", { CornerRadius = UDim.new(0, 8), Parent = tabContainer })
    createInstance("Frame", {
        Name = "CornerFiller",
        BackgroundColor3 = Library.CurrentTheme.Secondary,
        BorderSizePixel = 0,
        Size = UDim2.new(0, 10, 0, 10),
        Position = UDim2.new(1, -10, 0, 0),
        Parent = tabContainer
    })
    local contentContainer = createInstance("Frame", {
        Name = "ContentContainer",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -options.TabWidth, 1, -40),
        Position = UDim2.new(0, options.TabWidth, 0, 30),
        Parent = mainFrame
    })
    local tabScroller = createInstance("ScrollingFrame", {
        Name = "TabScroller",
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 1, -10),
        Position = UDim2.new(0, 0, 0, 5),
        CanvasSize = UDim2.new(0, 0, 0, 0),
        ScrollBarThickness = 2,
        ScrollBarImageColor3 = Library.CurrentTheme.TextDark,
        ScrollingDirection = Enum.ScrollingDirection.Y,
        ClipsDescendants = true,
        Parent = tabContainer
    })
    createInstance("UIListLayout", {
        FillDirection = Enum.FillDirection.Vertical,
        HorizontalAlignment = Enum.HorizontalAlignment.Center,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 5),
        Parent = tabScroller
    })
    createInstance("UIPadding", { PaddingTop = UDim.new(0, 5), Parent = tabScroller })

    -- Part 7: Window Constructor - AddTab Function
    function window:AddTab(options)
        options = options or {}
        options.Title = options.Title or "Tab"
        options.Icon = options.Icon or nil
        local tab = createInstance("TextButton", {
            Name = options.Title .. "Tab",
            BackgroundColor3 = Library.CurrentTheme.Secondary,
            BorderSizePixel = 0,
            Size = UDim2.new(1, -20, 0, 40),
            Text = "",
            Parent = tabScroller
        })
        createInstance("UICorner", { CornerRadius = UDim.new(0, 6), Parent = tab })
        local iconVisible = options.Icon ~= nil and options.Icon ~= ""
        local tabIcon
        if iconVisible then
            tabIcon = createInstance("ImageLabel", {
                Name = "TabIcon",
                BackgroundTransparency = 1,
                Size = UDim2.new(0, 20, 0, 20),
                Position = UDim2.new(0, 10, 0.5, -10),
                Image = Icons[options.Icon] or options.Icon,
                ImageColor3 = Library.CurrentTheme.TextDark,
                Parent = tab
            })
        end
        local tabTitle = createInstance("TextLabel", {
            Name = "TabTitle",
            BackgroundTransparency = 1,
            Size = UDim2.new(1, iconVisible and -40 or -20, 1, 0),
            Position = UDim2.new(0, iconVisible and 40 or 15, 0, 0),
            Text = options.Title,
            TextColor3 = Library.CurrentTheme.TextDark,
            TextSize = 15,
            TextXAlignment = Enum.TextXAlignment.Left,
            Font = Enum.Font.Gotham,
            Parent = tab
        })
        local tabContent = createInstance("ScrollingFrame", {
            Name = options.Title .. "Content",
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Size = UDim2.new(1, -20, 1, -20),
            Position = UDim2.new(0, 10, 0, 10),
            CanvasSize = UDim2.new(0, 0, 0, 0),
            ScrollBarThickness = 3,
            ScrollBarImageColor3 = Library.CurrentTheme.TextDark,
            ScrollingDirection = Enum.ScrollingDirection.Y,
            ClipsDescendants = true,
            Visible = false,
            Parent = contentContainer
        })
        createInstance("UIListLayout", {
            FillDirection = Enum.FillDirection.Vertical,
            HorizontalAlignment = Enum.HorizontalAlignment.Center,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 10),
            Parent = tabContent
        })
        createInstance("UIPadding", { PaddingTop = UDim.new(0, 5), Parent = tabContent })
        tabContent.UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            tabContent.CanvasSize = UDim2.new(0, 0, 0, tabContent.UIListLayout.AbsoluteContentSize.Y + 10)
        end)
        tabScroller.UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            tabScroller.CanvasSize = UDim2.new(0, 0, 0, tabScroller.UIListLayout.AbsoluteContentSize.Y + 10)
        end)
        tab.MouseEnter:Connect(function()
            if window.ActiveTab ~= options.Title then
                createTween(tab, TweenInfoHover, { BackgroundColor3 = Library.CurrentTheme.Tertiary })
                if iconVisible then
                    createTween(tabIcon, TweenInfoHover, { ImageColor3 = Library.CurrentTheme.Text })
                end
                createTween(tabTitle, TweenInfoHover, { TextColor3 = Library.CurrentTheme.Text })
            end
        end)
        tab.MouseLeave:Connect(function()
            if window.ActiveTab ~= options.Title then
                createTween(tab, TweenInfoHover, { BackgroundColor3 = Library.CurrentTheme.Secondary })
                if iconVisible then
                    createTween(tabIcon, TweenInfoHover, { ImageColor3 = Library.CurrentTheme.TextDark })
                end
                createTween(tabTitle, TweenInfoHover, { TextColor3 = Library.CurrentTheme.TextDark })
            end
        end)
        tab.MouseButton1Click:Connect(function()
            if window.ActiveTab ~= options.Title then
                selectTab(options.Title, window, Library.CurrentTheme)
            end
        end)
        window.TabCount = window.TabCount + 1
        window.Tabs[options.Title] = {
            Button = tab,
            Icon = tabIcon,
            Title = tabTitle,
            Content = tabContent,
            Sections = {},
            Elements = {}
        }
        if window.TabCount == 1 then
            selectTab(options.Title, window, Library.CurrentTheme)
        end
        local tabObj = { Content = tabContent, Sections = {} }

        -- Part 8: Window Constructor - AddSection and Add Elements
        function tabObj:AddSection(options)
            options = options or {}
            options.Title = options.Title or "Section"
            local section = createInstance("Frame", {
                Name = options.Title .. "Section",
                BackgroundColor3 = Library.CurrentTheme.Secondary,
                BorderSizePixel = 0,
                Size = UDim2.new(1, 0, 0, 40),
                AutomaticSize = Enum.AutomaticSize.Y,
                Parent = self.Content
            })
            createInstance("UICorner", { CornerRadius = UDim.new(0, 6), Parent = section })
            shadowEffect(section, 8, 0.2)
            createInstance("TextLabel", {
                Name = "SectionTitle",
                BackgroundTransparency = 1,
                Size = UDim2.new(1, -20, 0, 40),
                Position = UDim2.new(0, 10, 0, 0),
                Text = options.Title,
                TextColor3 = Library.CurrentTheme.Text,
                TextSize = 16,
                TextXAlignment = Enum.TextXAlignment.Left,
                Font = Enum.Font.GothamBold,
                Parent = section
            })
            local sectionContent = createInstance("Frame", {
                Name = "SectionContent",
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                Size = UDim2.new(1, -20, 0, 0),
                Position = UDim2.new(0, 10, 0, 40),
                AutomaticSize = Enum.AutomaticSize.Y,
                Parent = section
            })
            createInstance("UIListLayout", {
                FillDirection = Enum.FillDirection.Vertical,
                HorizontalAlignment = Enum.HorizontalAlignment.Center,
                SortOrder = Enum.SortOrder.LayoutOrder,
                Padding = UDim.new(0, 8),
                Parent = sectionContent
            })
            createInstance("UIPadding", { PaddingBottom = UDim.new(0, 10), Parent = sectionContent })
            sectionContent.UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                section.Size = UDim2.new(1, 0, 0, sectionContent.UIListLayout.AbsoluteContentSize.Y + 50)
            end)
            self.Sections[options.Title] = section
            local sectionObj = {}
            function sectionObj:AddButton(options)
                options = options or {}
                options.Title = options.Title or "Button"
                options.Callback = options.Callback or function() end
                local button = createInstance("TextButton", {
                    Name = "Button",
                    BackgroundColor3 = Library.CurrentTheme.Tertiary,
                    BorderSizePixel = 0,
                    Size = UDim2.new(1, -20, 0, 36),
                    Text = "",
                    Parent = sectionContent
                })
                createInstance("UICorner", { CornerRadius = UDim.new(0, 6), Parent = button })
                local buttonTitle = createInstance("TextLabel", {
                    Name = "ButtonTitle",
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, -20, 1, 0),
                    Position = UDim2.new(0, 10, 0, 0),
                    Text = options.Title,
                    TextColor3 = Library.CurrentTheme.Text,
                    TextSize = 15,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Font = Enum.Font.Gotham,
                    Parent = button
                })
                applyHoverEffect(
                    button,
                    Library.CurrentTheme.Tertiary,
                    Library.CurrentTheme.Accent,
                    buttonTitle,
                    Library.CurrentTheme.Text,
                    Color3.fromRGB(255, 255, 255)
                )
                applyClickEffect(button, Library.CurrentTheme.Tertiary, Library.CurrentTheme.AccentDark, options.Callback)
                local buttonObj = {}
                function buttonObj:SetText(text)
                    buttonTitle.Text = text
                end
                function buttonObj:SetCallback(callback)
                    options.Callback = callback
                end
                return buttonObj
            end
            function sectionObj:AddToggle(options)
                options = options or {}
                options.Title = options.Title or "Toggle"
                options.Default = options.Default or false
                options.Callback = options.Callback or function() end
                local toggle = createInstance("Frame", {
                    Name = options.Title .. "Toggle",
                    BackgroundColor3 = Library.CurrentTheme.Tertiary,
                    BorderSizePixel = 0,
                    Size = UDim2.new(1, 0, 0, 36),
                    Parent = sectionContent
                })
                createInstance("UICorner", { CornerRadius = UDim.new(0, 6), Parent = toggle })
                local toggleTitle = createInstance("TextLabel", {
                    Name = "ToggleTitle",
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, -60, 1, 0),
                    Position = UDim2.new(0, 10, 0, 0),
                    Text = options.Title,
                    TextColor3 = Library.CurrentTheme.Text,
                    TextSize = 15,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Font = Enum.Font.Gotham,
                    Parent = toggle
                })
                local toggleButton = createInstance("Frame", {
                    Name = "ToggleButton",
                    BackgroundColor3 = options.Default and Library.CurrentTheme.Accent or Library.CurrentTheme.Secondary,
                    BorderSizePixel = 0,
                    Size = UDim2.new(0, 40, 0, 22),
                    Position = UDim2.new(1, -50, 0.5, -11),
                    Parent = toggle
                })
                createInstance("UICorner", { CornerRadius = UDim.new(1, 0), Parent = toggleButton })
                local toggleCircle = createInstance("Frame", {
                    Name = "ToggleCircle",
                    BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                    BorderSizePixel = 0,
                    Size = UDim2.new(0, 16, 0, 16),
                    Position = UDim2.new(options.Default and 1 or 0, options.Default and -18 or 3, 0.5, -8),
                    Parent = toggleButton
                })
                createInstance("UICorner", { CornerRadius = UDim.new(1, 0), Parent = toggleCircle })
                local toggled = options.Default
                local function setToggle(value)
                    toggled = value
                    createTween(toggleButton, TweenInfoClick, {
                        BackgroundColor3 = toggled and Library.CurrentTheme.Accent or Library.CurrentTheme.Secondary
                    })
                    createTween(toggleCircle, TweenInfoClick, {
                        Position = UDim2.new(toggled and 1 or 0, toggled and -18 or 3, 0.5, -8)
                    })
                    options.Callback(toggled)
                end
                toggle.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        setToggle(not toggled)
                    end
                end)
                applyHoverEffect(
                    toggle,
                    Library.CurrentTheme.Tertiary,
                    Library.CurrentTheme.Accent,
                    toggleTitle,
                    Library.CurrentTheme.Text,
                    Color3.fromRGB(255, 255, 255)
                )
                local toggleObj = {}
                function toggleObj:Set(value)
                    setToggle(value)
                end
                function toggleObj:GetValue()
                    return toggled
                end
                return toggleObj
            end
            function sectionObj:AddSlider(options)
                options = options or {}
                options.Title = options.Title or "Slider"
                options.Min = options.Min or 0
                options.Max = options.Max or 100
                options.Default = options.Default or options.Min
                options.Increment = options.Increment or 1
                options.Callback = options.Callback or function() end
                options.Default = math.clamp(options.Default, options.Min, options.Max)
                local slider = createInstance("Frame", {
                    Name = options.Title .. "Slider",
                    BackgroundColor3 = Library.CurrentTheme.Tertiary,
                    BorderSizePixel = 0,
                    Size = UDim2.new(1, 0, 0, 50),
                    Parent = sectionContent
                })
                createInstance("UICorner", { CornerRadius = UDim.new(0, 6), Parent = slider })
                local sliderTitle = createInstance("TextLabel", {
                    Name = "SliderTitle",
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, -20, 0, 25),
                    Position = UDim2.new(0, 10, 0, 0),
                    Text = options.Title,
                    TextColor3 = Library.CurrentTheme.Text,
                    TextSize = 15,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Font = Enum.Font.Gotham,
                    Parent = slider
                })
                local sliderValue = createInstance("TextLabel", {
                    Name = "SliderValue",
                    BackgroundTransparency = 1,
                    Size = UDim2.new(0, 60, 0, 25),
                    Position = UDim2.new(1, -70, 0, 0),
                    Text = tostring(options.Default),
                    TextColor3 = Library.CurrentTheme.TextDark,
                    TextSize = 14,
                    TextXAlignment = Enum.TextXAlignment.Right,
                    Font = Enum.Font.Gotham,
                    Parent = slider
                })
                local sliderBack = createInstance("Frame", {
                    Name = "SliderBack",
                    BackgroundColor3 = Library.CurrentTheme.Secondary,
                    BorderSizePixel = 0,
                    Size = UDim2.new(1, -20, 0, 8),
                    Position = UDim2.new(0, 10, 0, 32),
                    Parent = slider
                })
                createInstance("UICorner", { CornerRadius = UDim.new(1, 0), Parent = sliderBack })
                local sliderFill = createInstance("Frame", {
                    Name = "SliderFill",
                    BackgroundColor3 = Library.CurrentTheme.Accent,
                    BorderSizePixel = 0,
                    Size = UDim2.new(((options.Default - options.Min) / (options.Max - options.Min)), 0, 1, 0),
                    Position = UDim2.new(0, 0, 0, 0),
                    Parent = sliderBack
                })
                createInstance("UICorner", { CornerRadius = UDim.new(1, 0), Parent = sliderFill })
                local sliderDot = createInstance("Frame", {
                    Name = "SliderDot",
                    BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                    BorderSizePixel = 0,
                    Size = UDim2.new(0, 12, 0, 12),
                    Position = UDim2.new(((options.Default - options.Min) / (options.Max - options.Min)), 0, 0.5, -6),
                    Parent = sliderBack
                })
                createInstance("UICorner", { CornerRadius = UDim.new(1, 0), Parent = sliderDot })
                local function setValue(value)
                    value = math.clamp(roundNumber(value, options.Increment), options.Min, options.Max)
                    sliderValue.Text = tostring(value)
                    updateSliderValue(sliderBack, sliderFill, sliderDot, options.Min, options.Max, value, options.Callback)
                end
                setValue(options.Default)
                local dragging = false
                sliderBack.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        dragging = true
                        local relativePos = input.Position.X - sliderBack.AbsolutePosition.X
                        local percent = math.clamp(relativePos / sliderBack.AbsoluteSize.X, 0, 1)
                        local value = options.Min + (options.Max - options.Min) * percent
                        setValue(value)
                    end
                end)
                sliderBack.InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        dragging = false
                    end
                end)
                UserInputService.InputChanged:Connect(function(input)
                    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                        local relativePos = input.Position.X - sliderBack.AbsolutePosition.X
                        local percent = math.clamp(relativePos / sliderBack.AbsoluteSize.X, 0, 1)
                        local value = options.Min + (options.Max - options.Min) * percent
                        setValue(value)
                    end
                end)
                applyHoverEffect(
                    slider,
                    Library.CurrentTheme.Tertiary,
                    Library.CurrentTheme.Accent,
                    sliderTitle,
                    Library.CurrentTheme.Text,
                    Color3.fromRGB(255, 255, 255)
                )
                local sliderObj = {}
                function sliderObj:SetValue(value)
                    setValue(value)
                end
                function sliderObj:GetValue()
                    return tonumber(sliderValue.Text)
                end
                return sliderObj
            end
            function sectionObj:AddDropdown(options)
                options = options or {}
                options.Title = options.Title or "Dropdown"
                options.Items = options.Items or {}
                options.Default = options.Default or nil
                options.Callback = options.Callback or function() end
                local dropdown = createInstance("Frame", {
                    Name = options.Title .. "Dropdown",
                    BackgroundColor3 = Library.CurrentTheme.Tertiary,
                    BorderSizePixel = 0,
                    Size = UDim2.new(1, 0, 0, 36),
                    ClipsDescendants = true,
                    Parent = sectionContent
                })
                createInstance("UICorner", { CornerRadius = UDim.new(0, 6), Parent = dropdown })
                local dropdownTitle = createInstance("TextLabel", {
                    Name = "DropdownTitle",
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, -40, 0, 36),
                    Position = UDim2.new(0, 10, 0, 0),
                    Text = options.Title,
                    TextColor3 = Library.CurrentTheme.Text,
                    TextSize = 15,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Font = Enum.Font.Gotham,
                    Parent = dropdown
                })
                createInstance("ImageLabel", {
                    Name = "DropdownArrow",
                    BackgroundTransparency = 1,
                    Size = UDim2.new(0, 20, 0, 20),
                    Position = UDim2.new(1, -30, 0, 8),
                    Image = Icons.dropdown,
                    ImageColor3 = Library.CurrentTheme.TextDark,
                    Parent = dropdown
                })
                local dropdownContent = createInstance("Frame", {
                    Name = "DropdownContent",
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    Size = UDim2.new(1, -20, 0, 0),
                    Position = UDim2.new(0, 10, 0, 40),
                    AutomaticSize = Enum.AutomaticSize.Y,
                    Parent = dropdown
                })
                createInstance("UIListLayout", {
                    FillDirection = Enum.FillDirection.Vertical,
                    HorizontalAlignment = Enum.HorizontalAlignment.Center,
                    SortOrder = Enum.SortOrder.LayoutOrder,
                    Padding = UDim.new(0, 5),
                    Parent = dropdownContent
                })
                createInstance("UIPadding", { PaddingBottom = UDim.new(0, 5), Parent = dropdownContent })
                local selected = options.Default
                local function updateDropdown()
                    if selected then
                        dropdownTitle.Text = options.Title .. ": " .. tostring(selected)
                    else
                        dropdownTitle.Text = options.Title
                    end
                end
                local toggleDropdown = toggleElement(
                    dropdown,
                    dropdownContent.UIListLayout,
                    UDim2.new(1, 0, 0, 36),
                    UDim2.new(1, 0, 0, 36 + dropdownContent.UIListLayout.AbsoluteContentSize.Y + 10),
                    dropdown.DropdownArrow
                )
                dropdown.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        toggleDropdown()
                    end
                end)
                for i, item in pairs(options.Items) do
                    local dropdownItem = createInstance("TextButton", {
                        Name = "DropdownItem",
                        BackgroundColor3 = Library.CurrentTheme.Secondary,
                        BorderSizePixel = 0,
                        Size = UDim2.new(1, 0, 0, 30),
                        Text = tostring(item),
                        TextColor3 = Library.CurrentTheme.Text,
                        TextSize = 14,
                        Font = Enum.Font.Gotham,
                        Parent = dropdownContent
                    })
                    createInstance("UICorner", { CornerRadius = UDim.new(0, 4), Parent = dropdownItem })
                    dropdownItem.MouseEnter:Connect(function()
                        createTween(dropdownItem, TweenInfoHover, { BackgroundColor3 = Library.CurrentTheme.Accent })
                    end)
                    dropdownItem.MouseLeave:Connect(function()
                        createTween(dropdownItem, TweenInfoHover, { BackgroundColor3 = Library.CurrentTheme.Secondary })
                    end)
                    dropdownItem.MouseButton1Click:Connect(function()
                        selected = item
                        updateDropdown()
                        options.Callback(selected)
                        toggleDropdown()
                    end)
                end
                updateDropdown()
                dropdown.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        toggleDropdown()
                    end
                end)
                applyHoverEffect(
                    dropdown,
                    Library.CurrentTheme.Tertiary,
                    Library.CurrentTheme.Accent,
                    dropdownTitle,
                    Library.CurrentTheme.Text,
                    Color3.fromRGB(255, 255, 255)
                )
                local dropdownObj = {}
                function dropdownObj:SetValue(value)
                    if table.find(options.Items, value) then
                        selected = value
                        updateDropdown()
                        options.Callback(selected)
                    end
                end
                function dropdownObj:GetValue()
                    return selected
                end
                function dropdownObj:Refresh(items)
                    for _, child in pairs(dropdownContent:GetChildren()) do
                        if child:IsA("TextButton") then
                            child:Destroy()
                        end
                    end
                    options.Items = items
                    for i, item in pairs(options.Items) do
                        local dropdownItem = createInstance("TextButton", {
                            Name = "DropdownItem",
                            BackgroundColor3 = Library.CurrentTheme.Secondary,
                            BorderSizePixel = 0,
                            Size = UDim2.new(1, 0, 0, 30),
                            Text = tostring(item),
                            TextColor3 = Library.CurrentTheme.Text,
                            TextSize = 14,
                            Font = Enum.Font.Gotham,
                            Parent = dropdownContent
                        })
                        createInstance("UICorner", { CornerRadius = UDim.new(0, 4), Parent = dropdownItem })
                        dropdownItem.MouseEnter:Connect(function()
                            createTween(dropdownItem, TweenInfoHover, { BackgroundColor3 = Library.CurrentTheme.Accent })
                        end)
                        dropdownItem.MouseLeave:Connect(function()
                            createTween(dropdownItem, TweenInfoHover, { BackgroundColor3 = Library.CurrentTheme.Secondary })
                        end)
                        dropdownItem.MouseButton1Click:Connect(function()
                            selected = item
                            updateDropdown()
                            options.Callback(selected)
                            toggleDropdown()
                        end)
                    end
                    if not table.find(options.Items, selected) then
                        selected = nil
                        updateDropdown()
                    end
                    if opened then
                        dropdown.Size = UDim2.new(1, 0, 0, 36 + dropdownContent.UIListLayout.AbsoluteContentSize.Y + 10)
                    end
                end
                return dropdownObj
            end
            function sectionObj:AddColorPicker(options)
                options = options or {}
                options.Title = options.Title or "ColorPicker"
                options.Default = options.Default or Color3.fromRGB(255, 255, 255)
                options.Callback = options.Callback or function() end
                local colorPicker = createInstance("Frame", {
                    Name = options.Title .. "ColorPicker",
                    BackgroundColor3 = Library.CurrentTheme.Tertiary,
                    BorderSizePixel = 0,
                    Size = UDim2.new(1, 0, 0, 36),
                    ClipsDescendants = true,
                    Parent = sectionContent
                })
                createInstance("UICorner", { CornerRadius = UDim.new(0, 6), Parent = colorPicker })
                local colorPickerTitle = createInstance("TextLabel", {
                    Name = "ColorPickerTitle",
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, -60, 0, 36),
                    Position = UDim2.new(0, 10, 0, 0),
                    Text = options.Title,
                    TextColor3 = Library.CurrentTheme.Text,
                    TextSize = 15,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Font = Enum.Font.Gotham,
                    Parent = colorPicker
                })
                local colorDisplay = createInstance("Frame", {
                    Name = "ColorDisplay",
                    BackgroundColor3 = options.Default,
                    BorderSizePixel = 0,
                    Size = UDim2.new(0, 20, 0, 20),
                    Position = UDim2.new(1, -30, 0.5, -10),
                    Parent = colorPicker
                })
                createInstance("UICorner", { CornerRadius = UDim.new(0, 4), Parent = colorDisplay })
                local colorPickerContent = createInstance("Frame", {
                    Name = "ColorPickerContent",
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    Size = UDim2.new(1, -20, 0, 0),
                    Position = UDim2.new(0, 10, 0, 40),
                    AutomaticSize = Enum.AutomaticSize.Y,
                    Parent = colorPicker
                })
                createInstance("UIListLayout", {
                    FillDirection = Enum.FillDirection.Vertical,
                    HorizontalAlignment = Enum.HorizontalAlignment.Center,
                    SortOrder = Enum.SortOrder.LayoutOrder,
                    Padding = UDim.new(0, 5),
                    Parent = colorPickerContent
                })
                createInstance("UIPadding", { PaddingBottom = UDim.new(0, 5), Parent = colorPickerContent })
                local opened = false
                local function toggleColorPicker()
                    opened = not opened
                    if opened then
                        createTween(colorPicker, TweenInfoNotification, {
                            Size = UDim2.new(1, 0, 0, 36 + colorPickerContent.UIListLayout.AbsoluteContentSize.Y + 10)
                        })
                    else
                        createTween(colorPicker, TweenInfoNotification, {
                            Size = UDim2.new(1, 0, 0, 36)
                        })
                    end
                end
                local function updateColor(color)
                    colorDisplay.BackgroundColor3 = color
                    options.Callback(color)
                end
                local colorSlider = createInstance("Frame", {
                    Name = "ColorSlider",
                    BackgroundColor3 = Library.CurrentTheme.Secondary,
                    BorderSizePixel = 0,
                    Size = UDim2.new(1, 0, 0, 20),
                    Parent = colorPickerContent
                })
                createInstance("UICorner", { CornerRadius = UDim.new(0, 4), Parent = colorSlider })
                createInstance("UIGradient", {
                    Color = ColorSequence.new({
                        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
                        ColorSequenceKeypoint.new(0.166, Color3.fromRGB(255, 255, 0)),
                        ColorSequenceKeypoint.new(0.333, Color3.fromRGB(0, 255, 0)),
                        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 255)),
                        ColorSequenceKeypoint.new(0.666, Color3.fromRGB(0, 0, 255)),
                        ColorSequenceKeypoint.new(0.833, Color3.fromRGB(255, 0, 255)),
                        ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0))
                    }),
                    Parent = colorSlider
                })
                local colorSliderDot = createInstance("Frame", {
                    Name = "ColorSliderDot",
                    BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                    BorderSizePixel = 0,
                    Size = UDim2.new(0, 8, 0, 8),
                    Position = UDim2.new(0.5, -4, 0.5, -4),
                    Parent = colorSlider
                })
                createInstance("UICorner", { CornerRadius = UDim.new(1, 0), Parent = colorSliderDot })
                local function updateColorFromSlider(position)
                    local percent = math.clamp((position - colorSlider.AbsolutePosition.X) / colorSlider.AbsoluteSize.X, 0, 1)
                    local color = Color3.fromHSV(percent, 1, 1)
                    updateColor(color)
                end
                local draggingSlider = false
                colorSlider.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        draggingSlider = true
                        updateColorFromSlider(input.Position.X)
                    end
                end)
                colorSlider.InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        draggingSlider = false
                    end
                end)
                UserInputService.InputChanged:Connect(function(input)
                    if draggingSlider and input.UserInputType == Enum.UserInputType.MouseMovement then
                        updateColorFromSlider(input.Position.X)
                    end
                end)
                local colorMatrix = createInstance("Frame", {
                    Name = "ColorMatrix",
                    BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                    BorderSizePixel = 0,
                    Size = UDim2.new(1, 0, 0, 100),
                    Parent = colorPickerContent
                })
                createInstance("UICorner", { CornerRadius = UDim.new(0, 4), Parent = colorMatrix })
                createInstance("UIGradient", {
                    Rotation = 90,
                    Color = ColorSequence.new({
                        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
                        ColorSequenceKeypoint.new(0.166, Color3.fromRGB(255, 255, 0)),
                        ColorSequenceKeypoint.new(0.333, Color3.fromRGB(0, 255, 0)),
                        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 255)),
                        ColorSequenceKeypoint.new(0.666, Color3.fromRGB(0, 0, 255)),
                        ColorSequenceKeypoint.new(0.833, Color3.fromRGB(255, 0, 255)),
                        ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0))
                    }),
                    Parent = colorMatrix
                })
                local matrixOverlay = createInstance("Frame", {
                    Name = "MatrixOverlay",
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    Size = UDim2.new(1, 0, 1, 0),
                    Parent = colorMatrix
                })
                createInstance("UIGradient", {
                    Color = ColorSequence.new({
                        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
                        ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255), 0)
                    }),
                    Parent = matrixOverlay
                })
                local colorMatrixDot = createInstance("Frame", {
                    Name = "ColorMatrixDot",
                    BackgroundColor3 = Color3.fromRGB(0, 0, 0),
                    BorderSizePixel = 0,
                    Size = UDim2.new(0, 8, 0, 8),
                    Position = UDim2.new(0.5, -4, 0.5, -4),
                    Parent = matrixOverlay
                })
                createInstance("UICorner", { CornerRadius = UDim.new(1, 0), Parent = colorMatrixDot })
                local function updateColorFromMatrix(position)
                    local h = Color3.toHSV(colorDisplay.BackgroundColor3)
                    local s = math.clamp((position.X - colorMatrix.AbsolutePosition.X) / colorMatrix.AbsoluteSize.X, 0, 1)
                    local v = 1 - math.clamp((position.Y - colorMatrix.AbsolutePosition.Y) / colorMatrix.AbsoluteSize.Y, 0, 1)
                    local color = Color3.fromHSV(h, s, v)
                    updateColor(color)
                end
                local draggingMatrix = false
                colorMatrix.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        draggingMatrix = true
                        updateColorFromMatrix(input.Position)
                    end
                end)
                colorMatrix.InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        draggingMatrix = false
                    end
                end)
                UserInputService.InputChanged:Connect(function(input)
                    if draggingMatrix and input.UserInputType == Enum.UserInputType.MouseMovement then
                        updateColorFromMatrix(input.Position)
                    end
                end)
                colorPicker.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        toggleColorPicker()
                    end
                end)
                applyHoverEffect(
                    colorPicker,
                    Library.CurrentTheme.Tertiary,
                    Library.CurrentTheme.Accent,
                    colorPickerTitle,
                    Library.CurrentTheme.Text,
                    Color3.fromRGB(255, 255, 255)
                )
                local colorPickerObj = {}
                function colorPickerObj:SetValue(color)
                    updateColor(color)
                    local h, s, v = Color3.toHSV(color)
                    local x = s * colorMatrix.AbsoluteSize.X
                    local y = (1 - v) * colorMatrix.AbsoluteSize.Y
                    colorMatrixDot.Position = UDim2.new(0, x - 4, 0, y - 4)
                    local sliderPercent = h
                    colorSliderDot.Position = UDim2.new(sliderPercent, 0, 0.5, -6)
                end
                function colorPickerObj:GetValue()
                    return colorDisplay.BackgroundColor3
                end
                colorPickerObj:SetValue(options.Default)
                return colorPickerObj
            end
            return sectionObj
        end
        return tabObj
    end
    return window
end

-- Part 10: Library Table
Library.CreateWindow = window.CreateWindow
Library.Themes = {
    Dark = {
        Primary = Color3.fromRGB(30, 30, 30),
        Secondary = Color3.fromRGB(40, 40, 40),
        Tertiary = Color3.fromRGB(50, 50, 50),
        Accent = Color3.fromRGB(100, 100, 255),
        AccentDark = Color3.fromRGB(80, 80, 200),
        Text = Color3.fromRGB(230, 230, 230),
        TextDark = Color3.fromRGB(150, 150, 150)
    },
    Light = {
        Primary = Color3.fromRGB(240, 240, 240),
        Secondary = Color3.fromRGB(230, 230, 230),
        Tertiary = Color3.fromRGB(220, 220, 220),
        Accent = Color3.fromRGB(80, 80, 200),
        AccentDark = Color3.fromRGB(60, 60, 180),
        Text = Color3.fromRGB(20, 20, 20),
        TextDark = Color3.fromRGB(100, 100, 100)
    }
}
Library.Unloaded = false
return Library
