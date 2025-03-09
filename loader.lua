-- RobloxFluentUI - A Modern UI Library for Roblox
-- Version 1.0.0

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

-- Lucide Icons from https://lucide.dev/icons
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

-- Services
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService")
local TextService = game:GetService("TextService")

-- Variables
local Player = Players.LocalPlayer
local Mouse = Player:GetMouse()
local Viewport = workspace.CurrentCamera.ViewportSize
local TweenInfo_Hover = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local TweenInfo_Click = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local TweenInfo_Notification = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

-- Utility Functions
local function CreateInstance(instanceType, properties)
    -- Ensure instanceType is valid
    if not instanceType or type(instanceType) ~= "string" then
        warn("Invalid instanceType provided to CreateInstance.")
        return nil
    end

    -- Create the instance
    local instance = Instance.new(instanceType)

    -- Apply properties to the instance
    if properties and type(properties) == "table" then
        for property, value in pairs(properties) do
            if property ~= "Parent" then
                -- Check if the property exists on the instance
                if instance[property] ~= nil then
                    instance[property] = value
                else
                    warn("Property '" .. property .. "' does not exist on instance of type '" .. instanceType .. "'.")
                end
            end
        end

        -- Set the parent last to avoid issues
        if properties.Parent then
            instance.Parent = properties.Parent
        end
    end

    return instance
end

local function CreateTween(object, info, properties)
    local tween = TweenService:Create(object, info, properties)
    tween:Play()
    return tween
end

local function RoundNumber(number, decimalPlaces)
    local factor = 10 ^ (decimalPlaces or 0)
    return math.floor(number * factor + 0.5) / factor
end

local function ShadowEffect(object, size, transparency)
    local shadow = CreateInstance("ImageLabel", {
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


-- ===== Utilities =====
local function ApplyHoverEffect(object, defaultColor, hoverColor, textObject, defaultTextColor, hoverTextColor)
    object.MouseEnter:Connect(function()
        CreateTween(object, TweenInfo_Hover, { BackgroundColor3 = hoverColor })
        if textObject then
            CreateTween(textObject, TweenInfo_Hover, { TextColor3 = hoverTextColor })
        end
    end)

    object.MouseLeave:Connect(function()
        CreateTween(object, TweenInfo_Hover, { BackgroundColor3 = defaultColor })
        if textObject then
            CreateTween(textObject, TweenInfo_Hover, { TextColor3 = defaultTextColor })
        end
    end)
end

local function ApplyClickEffect(object, defaultColor, clickColor, callback)
    object.MouseButton1Down:Connect(function()
        CreateTween(object, TweenInfo_Click, { BackgroundColor3 = clickColor })
    end)

    object.MouseButton1Up:Connect(function()
        CreateTween(object, TweenInfo_Click, { BackgroundColor3 = defaultColor })
    end)

    object.MouseButton1Click:Connect(function()
        if callback then callback() end
    end)
end

local function ToggleElement(element, contentLayout, defaultSize, expandedSize, arrowObject)
    local Opened = false

    return function()
        Opened = not Opened

        if Opened then
            CreateTween(element, TweenInfo_Notification, { Size = expandedSize })
            if arrowObject then
                CreateTween(arrowObject, TweenInfo_Notification, { Rotation = 180 })
            end
        else
            CreateTween(element, TweenInfo_Notification, { Size = defaultSize })
            if arrowObject then
                CreateTween(arrowObject, TweenInfo_Notification, { Rotation = 0 })
            end
        end
    end
end

local function UpdateSliderValue(sliderBack, sliderFill, sliderDot, min, max, value, callback)
    local percent = (value - min) / (max - min)
    sliderFill.Size = UDim2.new(percent, 0, 1, 0)
    sliderDot.Position = UDim2.new(percent, 0, 0.5, -6)
    if callback then callback(value) end
end

local function SelectTab(tabName, Window, currentTheme)
    if Window.ActiveTab then
        local activeTab = Window.Tabs[Window.ActiveTab]
        activeTab.Content.Visible = false
        CreateTween(activeTab.Button, TweenInfo_Hover, { BackgroundColor3 = currentTheme.Secondary })
        if activeTab.Icon then
            CreateTween(activeTab.Icon, TweenInfo_Hover, { ImageColor3 = currentTheme.TextDark })
        end
        CreateTween(activeTab.Title, TweenInfo_Hover, { TextColor3 = currentTheme.TextDark })
    end

    local newTab = Window.Tabs[tabName]
    newTab.Content.Visible = true
    CreateTween(newTab.Button, TweenInfo_Hover, { BackgroundColor3 = currentTheme.Accent })
    if newTab.Icon then
        CreateTween(newTab.Icon, TweenInfo_Hover, { ImageColor3 = currentTheme.Text })
    end
    CreateTween(newTab.Title, TweenInfo_Hover, { TextColor3 = currentTheme.Text })

    Window.ActiveTab = tabName
end

-- Dialog Constructor
function Library:Dialog(options)
    options = options or {}
    options.Title = options.Title or "Dialog"
    options.Content = options.Content or "This is a dialog box."
    options.Buttons = options.Buttons or {
        {
            Title = "OK",
            Callback = function() end
        }
    }

    local DialogGui = CreateInstance("ScreenGui", {
        Name = "DialogGui",
        Parent = CoreGui,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    })

    local DialogFrame = CreateInstance("Frame", {
        Name = "DialogFrame",
        BackgroundColor3 = Library.CurrentTheme.Primary,
        BorderSizePixel = 0,
        Position = UDim2.new(0.5, 0, 0.5, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Size = UDim2.new(0, 400, 0, 200),
        Parent = DialogGui
    })

    ShadowEffect(DialogFrame, 15, 0.3)

    local DialogCorner = CreateInstance("UICorner", {
        CornerRadius = UDim.new(0, 8),
        Parent = DialogFrame
    })

    local DialogTitle = CreateInstance("TextLabel", {
        Name = "DialogTitle",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -20, 0, 40),
        Position = UDim2.new(0, 10, 0, 5),
        Text = options.Title,
        TextColor3 = Library.CurrentTheme.Text,
        TextSize = 20,
        TextXAlignment = Enum.TextXAlignment.Left,
        Font = Enum.Font.GothamBold,
        Parent = DialogFrame
    })

    local DialogContent = CreateInstance("TextLabel", {
        Name = "DialogContent",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -20, 0, 90),
        Position = UDim2.new(0, 10, 0, 50),
        Text = options.Content,
        TextColor3 = Library.CurrentTheme.TextDark,
        TextSize = 16,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        Font = Enum.Font.Gotham,
        Parent = DialogFrame
    })

    local ButtonHolder = CreateInstance("Frame", {
        Name = "ButtonHolder",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 40),
        Position = UDim2.new(0, 0, 1, -50),
        Parent = DialogFrame
    })

    local ButtonLayout = CreateInstance("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        HorizontalAlignment = Enum.HorizontalAlignment.Right,
        Padding = UDim.new(0, 10),
        Parent = ButtonHolder
    })

    local Padding = CreateInstance("UIPadding", {
        PaddingRight = UDim.new(0, 10),
        Parent = ButtonHolder
    })

    for i, buttonInfo in ipairs(options.Buttons) do
        local Button = CreateInstance("TextButton", {
            Name = "Button",
            BackgroundColor3 = i == 1 and Library.CurrentTheme.Accent or Library.CurrentTheme.Secondary,
            Size = UDim2.new(0, 100, 0, 32),
            Text = buttonInfo.Title,
            TextColor3 = i == 1 and Color3.fromRGB(255, 255, 255) or Library.CurrentTheme.Text,
            TextSize = 14,
            Font = Enum.Font.GothamSemibold,
            Parent = ButtonHolder
        })

        local ButtonCorner = CreateInstance("UICorner", {
            CornerRadius = UDim.new(0, 6),
            Parent = Button
        })

        -- Define ButtonTitle here
        local ButtonTitle = CreateInstance("TextLabel", {
            Name = "ButtonTitle",
            BackgroundTransparency = 1,
            Size = UDim2.new(1, -20, 1, 0),
            Position = UDim2.new(0, 10, 0, 0),
            Text = buttonInfo.Title,
            TextColor3 = i == 1 and Color3.fromRGB(255, 255, 255) or Library.CurrentTheme.Text,
            TextSize = 14,
            Font = Enum.Font.GothamSemibold,
            Parent = Button
        })

        -- Now use ButtonTitle in ApplyHoverEffect
        ApplyHoverEffect(
            Button,
            i == 1 and Library.CurrentTheme.Accent or Library.CurrentTheme.Secondary,
            i == 1 and Library.CurrentTheme.AccentDark or Library.CurrentTheme.Tertiary,
            ButtonTitle,
            i == 1 and Color3.fromRGB(255, 255, 255) or Library.CurrentTheme.Text,
            Color3.fromRGB(255, 255, 255)
        )

        ApplyClickEffect(
            Button,
            i == 1 and Library.CurrentTheme.Accent or Library.CurrentTheme.Secondary,
            i == 1 and Library.CurrentTheme.AccentDark or Library.CurrentTheme.Tertiary,
            function()
                if buttonInfo.Callback then
                    buttonInfo.Callback()
                end
                DialogGui:Destroy()
            end
        )
    end
end

-- Notification Constructor
function Library:Notify(options)
    options = options or {}
    options.Title = options.Title or "Notification"
    options.Content = options.Content or "This is a notification."
    options.SubContent = options.SubContent or nil
    options.Duration = options.Duration or 5

    local Notifications = CoreGui:FindFirstChild("Notifications")
    if not Notifications then
        Notifications = CreateInstance("ScreenGui", {
            Name = "Notifications",
            Parent = CoreGui,
            ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        })

        local NotificationHolder = CreateInstance("Frame", {
            Name = "NotificationHolder",
            BackgroundTransparency = 1,
            Size = UDim2.new(0, 300, 1, 0),
            Position = UDim2.new(1, -310, 0, 0),
            Parent = Notifications
        })

        local NotificationLayout = CreateInstance("UIListLayout", {
            FillDirection = Enum.FillDirection.Vertical,
            HorizontalAlignment = Enum.HorizontalAlignment.Right,
            Padding = UDim.new(0, 10),
            VerticalAlignment = Enum.VerticalAlignment.Bottom,
            Parent = NotificationHolder
        })

        local Padding = CreateInstance("UIPadding", {
            PaddingBottom = UDim.new(0, 10),
            Parent = NotificationHolder
        })
    end

    local NotificationHolder = Notifications.NotificationHolder

    local Notification = CreateInstance("Frame", {
        Name = "Notification",
        BackgroundColor3 = Library.CurrentTheme.Primary,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, options.SubContent and 100 or 80),
        Position = UDim2.new(1, 0, 0, 0),
        Parent = NotificationHolder
    })

    ShadowEffect(Notification, 10, 0.3)

    local NotificationCorner = CreateInstance("UICorner", {
        CornerRadius = UDim.new(0, 8),
        Parent = Notification
    })

    local NotificationIcon = CreateInstance("ImageLabel", {
        Name = "NotificationIcon",
        BackgroundTransparency = 1,
        Size = UDim2.new(0, 24, 0, 24),
        Position = UDim2.new(0, 15, 0, 15),
        Image = Icons.alert,
        ImageColor3 = Library.CurrentTheme.Accent,
        Parent = Notification
    })

    local NotificationTitle = CreateInstance("TextLabel", {
        Name = "NotificationTitle",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -60, 0, 24),
        Position = UDim2.new(0, 50, 0, 15),
        Text = options.Title,
        TextColor3 = Library.CurrentTheme.Text,
        TextSize = 18,
        TextXAlignment = Enum.TextXAlignment.Left,
        Font = Enum.Font.GothamBold,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Parent = Notification
    })

    local NotificationContent = CreateInstance("TextLabel", {
        Name = "NotificationContent",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -30, 0, options.SubContent and 25 or 40),
        Position = UDim2.new(0, 15, 0, 40),
        Text = options.Content,
        TextColor3 = Library.CurrentTheme.TextDark,
        TextSize = 15,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        Font = Enum.Font.Gotham,
        Parent = Notification
    })

    if options.SubContent then
        local NotificationSubContent = CreateInstance("TextLabel", {
            Name = "NotificationSubContent",
            BackgroundTransparency = 1,
            Size = UDim2.new(1, -30, 0, 25),
            Position = UDim2.new(0, 15, 0, 65),
            Text = options.SubContent,
            TextColor3 = Library.CurrentTheme.TextDark,
            TextSize = 13,
            TextWrapped = true,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Top,
            Font = Enum.Font.Gotham,
            TextTransparency = 0.3,
            Parent = Notification
        })
    end

    CreateTween(Notification, TweenInfo_Notification, {
        Position = UDim2.new(0, 0, 0, 0)
    })

    if options.Duration then
        task.spawn(function()
            task.wait(options.Duration)

            if Notification and Notification.Parent then
                CreateTween(Notification, TweenInfo_Notification, {
                    Position = UDim2.new(1, 0, 0, 0)
                }).Completed:Connect(function()
                    Notification:Destroy()
                end)
            end
        end)
    end

    return Notification
end

-- Window Constructor
function Library:CreateWindow(options)
    options = options or {}
    options.Title = options.Title or "FluentUI"
    options.SubTitle = options.SubTitle or "by ItsYourDev"
    options.TabWidth = options.TabWidth or 160
    options.Size = options.Size or UDim2.fromOffset(580, 460)
    options.Acrylic = options.Acrylic ~= nil and options.Acrylic or true
    options.Theme = options.Theme or "Dark"
    options.MinimizeKey = options.MinimizeKey or Enum.KeyCode.RightControl

    -- Initialize Window table
    local Window = {
        Tabs = {},
        ActiveTab = nil,
        TabCount = 0
    }

    -- Set Theme
    Library.CurrentTheme = Library.Themes[options.Theme]

    -- Create Main GUI
    local MainGui = CreateInstance("ScreenGui", {
        Name = "FluentUI",
        Parent = CoreGui,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        ResetOnSpawn = false
    })

    local MainFrame = CreateInstance("Frame", {
        Name = "MainFrame",
        BackgroundColor3 = Library.CurrentTheme.Primary,
        BorderSizePixel = 0,
        Position = UDim2.new(0.5, 0, 0.5, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Size = options.Size,
        Parent = MainGui
    })

    -- Apply shadow
    ShadowEffect(MainFrame, 15, 0.5)

    -- Apply Acrylic Effect (Blur) if enabled
    if options.Acrylic then
        local Blur = CreateInstance("Frame", {
            Name = "AcrylicBlur",
            BackgroundTransparency = 0.85,
            BackgroundColor3 = Library.CurrentTheme.Primary,
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 1, 0),
            ZIndex = 0,
            Parent = MainFrame
        })

        local BlurEffect = CreateInstance("BlurEffect", {
            Name = "Blur",
            Size = 6,
            Parent = Blur
        })
    end

    local MainCorner = CreateInstance("UICorner", {
        CornerRadius = UDim.new(0, 8),
        Parent = MainFrame
    })
    -- Top Bar
    -- Top Bar
    local TopBar = CreateInstance("Frame", {
        Name = "TopBar",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 30),
        Parent = MainFrame
    })

    -- Title
-- Title
    local Title = CreateInstance("TextLabel", {
        Name = "Title",
        BackgroundTransparency = 1,
        Size = UDim2.new(0, 200, 1, 0),
        Position = UDim2.new(0, 15, 0, 0),
        Text = options.Title,
        TextColor3 = Library.CurrentTheme.Text,
        TextSize = 18,
        TextXAlignment = Enum.TextXAlignment.Left,
        Font = Enum.Font.GothamBold,
        Parent = TopBar
    })

-- Debugging: Check if Title is nil
    if not Title then
        warn("Failed to create Title object. Check the CreateInstance function.")
        return
    end

    -- Calculate the size of the title text
    local TitleTextSize = TextService:GetTextSize(options.Title, Title.TextSize, Title.Font, Vector2.new(1000, 1000))

    -- SubTitle
    local SubTitle = CreateInstance("TextLabel", {
        Name = "SubTitle",
        BackgroundTransparency = 1,
        Size = UDim2.new(0, 200, 1, 0),
        Position = UDim2.new(0, 15 + TitleTextSize.X + 10, 0, 0), -- Position after the title with a small gap
        Text = options.SubTitle,
        TextColor3 = Library.CurrentTheme.TextDark,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        Font = Enum.Font.Gotham,
        Parent = TopBar
    })

    -- Control Buttons
    local ControlButtons = CreateInstance("Frame", {
        Name = "ControlButtons",
        BackgroundTransparency = 1,
        Size = UDim2.new(0, 60, 1, 0),
        Position = UDim2.new(1, -65, 0, 0),
        Parent = TopBar
    })

    local MinimizeButton = CreateInstance("ImageButton", {
        Name = "MinimizeButton",
        BackgroundTransparency = 1,
        Size = UDim2.new(0, 20, 0, 20),
        Position = UDim2.new(0, 5, 0, 5),
        Image = Icons.minimize,
        ImageColor3 = Library.CurrentTheme.TextDark,
        Parent = ControlButtons
    })

    local CloseButton = CreateInstance("ImageButton", {
        Name = "CloseButton",
        BackgroundTransparency = 1,
        Size = UDim2.new(0, 20, 0, 20),
        Position = UDim2.new(0, 35, 0, 5),
        Image = Icons.close,
        ImageColor3 = Library.CurrentTheme.TextDark,
        Parent = ControlButtons
    })

    -- Make Top Bar draggable
    local Dragging = false
    local DragInput
    local DragStart
    local StartPos

    local function UpdateDrag(input)
        local Delta = input.Position - DragStart
        MainFrame.Position = UDim2.new(StartPos.X.Scale, StartPos.X.Offset + Delta.X, StartPos.Y.Scale, StartPos.Y.Offset + Delta.Y)
    end

    TopBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            Dragging = true
            DragStart = input.Position
            StartPos = MainFrame.Position

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    Dragging = false
                end
            end)
        end
    end)

    TopBar.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            DragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == DragInput and Dragging then
            UpdateDrag(input)
        end
    end)

    -- Control Button Functionality
    local Minimized = false
    local MinimizeSize = UDim2.new(1, 0, 0, 30)
    local OriginalSize = options.Size

    MinimizeButton.MouseButton1Click:Connect(function()
        Minimized = not Minimized

        if Minimized then
            MinimizeButton.Image = Icons.restore
            local Tween = CreateTween(MainFrame, TweenInfo_Notification, {
                Size = MinimizeSize
            })
        else
            MinimizeButton.Image = Icons.minimize
            local Tween = CreateTween(MainFrame, TweenInfo_Notification, {
                Size = OriginalSize
            })
        end
    end)

    MinimizeButton.MouseEnter:Connect(function()
        CreateTween(MinimizeButton, TweenInfo_Hover, {
            ImageColor3 = Library.CurrentTheme.Text
        })
    end)

    MinimizeButton.MouseLeave:Connect(function()
        CreateTween(MinimizeButton, TweenInfo_Hover, {
            ImageColor3 = Library.CurrentTheme.TextDark
        })
    end)

    CloseButton.MouseButton1Click:Connect(function()
        CreateTween(MainGui, TweenInfo_Notification, {
            Position = UDim2.new(1, 0, 0, 0)
        }).Completed:Connect(function()
            MainGui:Destroy()
            Library.Unloaded = true
        end)
    end)

    CloseButton.MouseEnter:Connect(function()
        CreateTween(CloseButton, TweenInfo_Hover, {
            ImageColor3 = Color3.fromRGB(255, 100, 100)
        })
    end)

    CloseButton.MouseLeave:Connect(function()
        CreateTween(CloseButton, TweenInfo_Hover, {
            ImageColor3 = Library.CurrentTheme.TextDark
        })
    end)

    -- Keybind to minimize
    UserInputService.InputBegan:Connect(function(input, processed)
        if not processed and input.KeyCode == options.MinimizeKey then
            Minimized = not Minimized

            if Minimized then
                MinimizeButton.Image = Icons.restore
                local Tween = CreateTween(MainFrame, TweenInfo_Notification, {
                    Size = MinimizeSize
                })
            else
                MinimizeButton.Image = Icons.minimize
                local Tween = CreateTween(MainFrame, TweenInfo_Notification, {
                    Size = OriginalSize
                })
            end
        end
    end)

    -- Main Content Containers
    local TabContainer = CreateInstance("Frame", {
        Name = "TabContainer",
        BackgroundColor3 = Library.CurrentTheme.Secondary,
        BorderSizePixel = 0,
        Size = UDim2.new(0, options.TabWidth, 1, -30),
        Position = UDim2.new(0, 0, 0, 30),
        Parent = MainFrame
    })

    local TabContainerCorner = CreateInstance("UICorner", {
        CornerRadius = UDim.new(0, 8),
        Parent = TabContainer
    })

    -- This Corner filler to fix the visual corner issue between TabContainer and MainFrame
    local CornerFiller = CreateInstance("Frame", {
        Name = "CornerFiller",
        BackgroundColor3 = Library.CurrentTheme.Secondary,
        BorderSizePixel = 0,
        Size = UDim2.new(0, 10, 0, 10),
        Position = UDim2.new(1, -10, 0, 0),
        Parent = TabContainer
    })

    local ContentContainer = CreateInstance("Frame", {
        Name = "ContentContainer",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -options.TabWidth, 1, -40),
        Position = UDim2.new(0, options.TabWidth, 0, 30),
        Parent = MainFrame
    })

    local TabScroller = CreateInstance("ScrollingFrame", {
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
        Parent = TabContainer
    })

    local TabListLayout = CreateInstance("UIListLayout", {
        FillDirection = Enum.FillDirection.Vertical,
        HorizontalAlignment = Enum.HorizontalAlignment.Center,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 5),
        Parent = TabScroller
    })

    local TabPadding = CreateInstance("UIPadding", {
        PaddingTop = UDim.new(0, 5),
        Parent = TabScroller
    })

    -- Window Functions and Properties
    local Window = {
        Tabs = {},
        ActiveTab = nil,
        TabCount = 0
    }

    function Window:AddTab(options)
        options = options or {}
        options.Title = options.Title or "Tab"
        options.Icon = options.Icon or nil

        -- Create tab button
        local Tab = CreateInstance("TextButton", {
            Name = options.Title.."Tab",
            BackgroundColor3 = Library.CurrentTheme.Secondary,
            BorderSizePixel = 0,
            Size = UDim2.new(1, -20, 0, 40),
            Text = "",
            Parent = TabScroller
        })

        local TabCorner = CreateInstance("UICorner", {
            CornerRadius = UDim.new(0, 6),
            Parent = Tab
        })

        local IconVisible = options.Icon ~= nil and options.Icon ~= ""

        local TabIcon
        if IconVisible then
            TabIcon = CreateInstance("ImageLabel", {
                Name = "TabIcon",
                BackgroundTransparency = 1,
                Size = UDim2.new(0, 20, 0, 20),
                Position = UDim2.new(0, 10, 0.5, -10),
                Image = Icons[options.Icon] or options.Icon,
                ImageColor3 = Library.CurrentTheme.TextDark,
                Parent = Tab
            })
        end

        local TabTitle = CreateInstance("TextLabel", {
            Name = "TabTitle",
            BackgroundTransparency = 1,
            Size = UDim2.new(1, IconVisible and -40 or -20, 1, 0),
            Position = UDim2.new(0, IconVisible and 40 or 15, 0, 0),
            Text = options.Title,
            TextColor3 = Library.CurrentTheme.TextDark,
            TextSize = 15,
            TextXAlignment = Enum.TextXAlignment.Left,
            Font = Enum.Font.Gotham,
            Parent = Tab
        })

        -- Create tab content
        local TabContent = CreateInstance("ScrollingFrame", {
            Name = options.Title.."Content",
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
            Parent = ContentContainer
        })

        local ContentListLayout = CreateInstance("UIListLayout", {
            FillDirection = Enum.FillDirection.Vertical,
            HorizontalAlignment = Enum.HorizontalAlignment.Center,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 10),
            Parent = TabContent
        })

        local ContentPadding = CreateInstance("UIPadding", {
            PaddingTop = UDim.new(0, 5),
            Parent = TabContent
        })

        -- Update scroll sizes
        ContentListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            TabContent.CanvasSize = UDim2.new(0, 0, 0, ContentListLayout.AbsoluteContentSize.Y + 10)
        end)

        TabListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            TabScroller.CanvasSize = UDim2.new(0, 0, 0, TabListLayout.AbsoluteContentSize.Y + 10)
        end)

        -- Tab hover effects
        Tab.MouseEnter:Connect(function()
            if Window.ActiveTab ~= options.Title then
                CreateTween(Tab, TweenInfo_Hover, {
                    BackgroundColor3 = Library.CurrentTheme.Tertiary
                })
                if IconVisible then
                    CreateTween(TabIcon, TweenInfo_Hover, {
                        ImageColor3 = Library.CurrentTheme.Text
                    })
                end
                CreateTween(TabTitle, TweenInfo_Hover, {
                    TextColor3 = Library.CurrentTheme.Text
                })
            end
        end)

        Tab.MouseLeave:Connect(function()

            if Window.ActiveTab ~= options.Title then
                CreateTween(Tab, TweenInfo_Hover, {
                    BackgroundColor3 = Library.CurrentTheme.Secondary
                })
                if IconVisible then
                    CreateTween(TabIcon, TweenInfo_Hover, {
                        ImageColor3 = Library.CurrentTheme.TextDark
                    })
                end
                CreateTween(TabTitle, TweenInfo_Hover, {
                    TextColor3 = Library.CurrentTheme.TextDark
                })
            end
        end)

        -- Tab selection
        Tab.MouseButton1Click:Connect(function()
            if Window.ActiveTab ~= options.Title then
                SelectTab(options.Title, Window, Library.CurrentTheme)
            end
        end)

        -- Add tab to window
        Window.TabCount = Window.TabCount + 1
        Window.Tabs[options.Title] = {
            Button = Tab,
            Icon = TabIcon,
            Title = TabTitle,
            Content = TabContent,
            Sections = {},
            Elements = {}
        }

        -- If this is the first tab, make it active
        if Window.TabCount == 1 then
            SelectTab(options.Title, Window, Library.CurrentTheme)
        end

        -- Tab Functions
        local TabObj = {
            Content = TabContent, -- Make the content container accessible
            Sections = {}
}

        function TabObj:AddSection(options)
            options = options or {}
            options.Title = options.Title or "Section"

            local Section = CreateInstance("Frame", {
                Name = options.Title.."Section",
                BackgroundColor3 = Library.CurrentTheme.Secondary,
                BorderSizePixel = 0,
                Size = UDim2.new(1, 0, 0, 40),
                AutomaticSize = Enum.AutomaticSize.Y,
                Parent = self.Content -- Use the tab's content container
            })

            local SectionCorner = CreateInstance("UICorner", {
                CornerRadius = UDim.new(0, 6),
                Parent = Section
            })

            ShadowEffect(Section, 8, 0.2)

            local SectionTitle = CreateInstance("TextLabel", {
                Name = "SectionTitle",
                BackgroundTransparency = 1,
                Size = UDim2.new(1, -20, 0, 40),
                Position = UDim2.new(0, 10, 0, 0),
                Text = options.Title,
                TextColor3 = Library.CurrentTheme.Text,
                TextSize = 16,
                TextXAlignment = Enum.TextXAlignment.Left,
                Font = Enum.Font.GothamBold,
                Parent = Section
            })

            local SectionContent = CreateInstance("Frame", {
                Name = "SectionContent",
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                Size = UDim2.new(1, -20, 0, 0),
                Position = UDim2.new(0, 10, 0, 40),
                AutomaticSize = Enum.AutomaticSize.Y,
                Parent = Section
            })

            local SectionListLayout = CreateInstance("UIListLayout", {
                FillDirection = Enum.FillDirection.Vertical,
                HorizontalAlignment = Enum.HorizontalAlignment.Center,
                SortOrder = Enum.SortOrder.LayoutOrder,
                Padding = UDim.new(0, 8),
                Parent = SectionContent
            })

            local SectionPadding = CreateInstance("UIPadding", {
                PaddingBottom = UDim.new(0, 10),
                Parent = SectionContent
            })

            -- Update section size when content changes
            SectionListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                Section.Size = UDim2.new(1, 0, 0, SectionListLayout.AbsoluteContentSize.Y + 50)
            end)

            -- Add section to tab
            self.Sections[options.Title] = Section

            local SectionObj = {}

            -- Button Element
            function SectionObj:AddButton(options)
                options = options or {}
                options.Title = options.Title or "Button"
                options.Callback = options.Callback or function() end

                local Button = CreateInstance("TextButton", {
                    Name = "Button",
                    BackgroundColor3 = Library.CurrentTheme.Tertiary,
                    BorderSizePixel = 0,
                    Size = UDim2.new(1, -20, 0, 36),
                    Text = "",
                    Parent = SectionContent
                })

                local ButtonCorner = CreateInstance("UICorner", {
                    CornerRadius = UDim.new(0, 6),
                    Parent = Button
                })

                -- Define ButtonTitle here
                local ButtonTitle = CreateInstance("TextLabel", {
                    Name = "ButtonTitle",
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, -20, 1, 0),
                    Position = UDim2.new(0, 10, 0, 0),
                    Text = options.Title,
                    TextColor3 = Library.CurrentTheme.Text,
                    TextSize = 15,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Font = Enum.Font.Gotham,
                    Parent = Button
                })

                -- Now use ButtonTitle in ApplyHoverEffect and ApplyClickEffect
                ApplyHoverEffect(
                    Button,
                    Library.CurrentTheme.Tertiary,
                    Library.CurrentTheme.Accent,
                    ButtonTitle,
                    Library.CurrentTheme.Text,
                    Color3.fromRGB(255, 255, 255)
                )

                ApplyClickEffect(
                    Button,
                    Library.CurrentTheme.Tertiary,
                    Library.CurrentTheme.AccentDark,
                    options.Callback
                )

                local ButtonObj = {}

                function ButtonObj:SetText(text)
                    ButtonTitle.Text = text
                end

                function ButtonObj:SetCallback(callback)
                    options.Callback = callback
                end

                return ButtonObj
            end

            -- Toggle Element
            function SectionObj:AddToggle(options)
                options = options or {}
                options.Title = options.Title or "Toggle"
                options.Default = options.Default or false
                options.Callback = options.Callback or function() end

                local Toggle = CreateInstance("Frame", {
                    Name = options.Title.."Toggle",
                    BackgroundColor3 = Library.CurrentTheme.Tertiary,
                    BorderSizePixel = 0,
                    Size = UDim2.new(1, 0, 0, 36),
                    Parent = SectionContent
                })

                local ToggleCorner = CreateInstance("UICorner", {
                    CornerRadius = UDim.new(0, 6),
                    Parent = Toggle
                })

                local ToggleTitle = CreateInstance("TextLabel", {
                    Name = "ToggleTitle",
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, -60, 1, 0),
                    Position = UDim2.new(0, 10, 0, 0),
                    Text = options.Title,
                    TextColor3 = Library.CurrentTheme.Text,
                    TextSize = 15,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Font = Enum.Font.Gotham,
                    Parent = Toggle
                })

                local ToggleButton = CreateInstance("Frame", {
                    Name = "ToggleButton",
                    BackgroundColor3 = options.Default and Library.CurrentTheme.Accent or Library.CurrentTheme.Secondary,
                    BorderSizePixel = 0,
                    Size = UDim2.new(0, 40, 0, 22),
                    Position = UDim2.new(1, -50, 0.5, -11),
                    Parent = Toggle
                })

                local ToggleButtonCorner = CreateInstance("UICorner", {
                    CornerRadius = UDim.new(1, 0),
                    Parent = ToggleButton
                })

                local ToggleCircle = CreateInstance("Frame", {
                    Name = "ToggleCircle",
                    BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                    BorderSizePixel = 0,
                    Size = UDim2.new(0, 16, 0, 16),
                    Position = UDim2.new(options.Default and 1 or 0, options.Default and -18 or 3, 0.5, -8),
                    Parent = ToggleButton
                })

                local ToggleCircleCorner = CreateInstance("UICorner", {
                    CornerRadius = UDim.new(1, 0),
                    Parent = ToggleCircle
                })

                local Toggled = options.Default

                local function SetToggle(value)
                    Toggled = value
                    CreateTween(ToggleButton, TweenInfo_Click, {
                        BackgroundColor3 = Toggled and Library.CurrentTheme.Accent or Library.CurrentTheme.Secondary
                    })
                    CreateTween(ToggleCircle, TweenInfo_Click, {
                        Position = UDim2.new(Toggled and 1 or 0, Toggled and -18 or 3, 0.5, -8)
                    })
                    options.Callback(Toggled)
                end

                Toggle.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        SetToggle(not Toggled)
                    end
                end)

                -- Toggle hover effects
                ApplyHoverEffect(
                    Toggle,
                    Library.CurrentTheme.Tertiary,
                    Library.CurrentTheme.Accent,
                    ToggleTitle,
                    Library.CurrentTheme.Text,
                    Color3.fromRGB(255, 255, 255)
                )

                local ToggleObj = {}

                function ToggleObj:Set(value)
                    SetToggle(value)
                end

                function ToggleObj:GetValue()
                    return Toggled
                end

                return ToggleObj
            end

            -- Slider Element
            function SectionObj:AddSlider(options)
                options = options or {}
                options.Title = options.Title or "Slider"
                options.Min = options.Min or 0
                options.Max = options.Max or 100
                options.Default = options.Default or options.Min
                options.Increment = options.Increment or 1
                options.Callback = options.Callback or function() end

                options.Default = math.clamp(options.Default, options.Min, options.Max)

                local Slider = CreateInstance("Frame", {
                    Name = options.Title.."Slider",
                    BackgroundColor3 = Library.CurrentTheme.Tertiary,
                    BorderSizePixel = 0,
                    Size = UDim2.new(1, 0, 0, 50),
                    Parent = SectionContent
                })

                local SliderCorner = CreateInstance("UICorner", {
                    CornerRadius = UDim.new(0, 6),
                    Parent = Slider
                })

                local SliderTitle = CreateInstance("TextLabel", {
                    Name = "SliderTitle",
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, -20, 0, 25),
                    Position = UDim2.new(0, 10, 0, 0),
                    Text = options.Title,
                    TextColor3 = Library.CurrentTheme.Text,
                    TextSize = 15,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Font = Enum.Font.Gotham,
                    Parent = Slider
                })

                local SliderValue = CreateInstance("TextLabel", {
                    Name = "SliderValue",
                    BackgroundTransparency = 1,
                    Size = UDim2.new(0, 60, 0, 25),
                    Position = UDim2.new(1, -70, 0, 0),
                    Text = tostring(options.Default),
                    TextColor3 = Library.CurrentTheme.TextDark,
                    TextSize = 14,
                    TextXAlignment = Enum.TextXAlignment.Right,
                    Font = Enum.Font.Gotham,
                    Parent = Slider
                })

                local SliderBack = CreateInstance("Frame", {
                    Name = "SliderBack",
                    BackgroundColor3 = Library.CurrentTheme.Secondary,
                    BorderSizePixel = 0,
                    Size = UDim2.new(1, -20, 0, 8),
                    Position = UDim2.new(0, 10, 0, 32),
                    Parent = Slider
                })

                local SliderBackCorner = CreateInstance("UICorner", {
                    CornerRadius = UDim.new(1, 0),
                    Parent = SliderBack
                })

                local SliderFill = CreateInstance("Frame", {
                    Name = "SliderFill",
                    BackgroundColor3 = Library.CurrentTheme.Accent,
                    BorderSizePixel = 0,
                    Size = UDim2.new(((options.Default - options.Min) / (options.Max - options.Min)), 0, 1, 0),
                    Position = UDim2.new(0, 0, 0, 0),
                    Parent = SliderBack
                })

                local SliderFillCorner = CreateInstance("UICorner", {
                    CornerRadius = UDim.new(1, 0),
                    Parent = SliderFill
                })

                local SliderDot = CreateInstance("Frame", {
                    Name = "SliderDot",
                    BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                    BorderSizePixel = 0,
                    Size = UDim2.new(0, 12, 0, 12),
                    Position = UDim2.new(((options.Default - options.Min) / (options.Max - options.Min)), 0, 0.5, -6),
                    Parent = SliderBack
                })

                local SliderDotCorner = CreateInstance("UICorner", {
                    CornerRadius = UDim.new(1, 0),
                    Parent = SliderDot
                })

                -- Slider functionality
                local function SetValue(value)
                    value = math.clamp(RoundNumber(value, options.Increment), options.Min, options.Max)
                    SliderValue.Text = tostring(value)
                    UpdateSliderValue(SliderBack, SliderFill, SliderDot, options.Min, options.Max, value, options.Callback)
                end

                -- Initialize slider with default value
                SetValue(options.Default)

                local Dragging = false

                SliderBack.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        Dragging = true

                        local relativePos = input.Position.X - SliderBack.AbsolutePosition.X
                        local percent = math.clamp(relativePos / SliderBack.AbsoluteSize.X, 0, 1)
                        local value = options.Min + (options.Max - options.Min) * percent

                        SetValue(value)
                    end
                end)

                SliderBack.InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        Dragging = false
                    end
                end)

                UserInputService.InputChanged:Connect(function(input)
                    if Dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                        local relativePos = input.Position.X - SliderBack.AbsolutePosition.X
                        local percent = math.clamp(relativePos / SliderBack.AbsoluteSize.X, 0, 1)
                        local value = options.Min + (options.Max - options.Min) * percent

                        SetValue(value)
                    end
                end)

                -- Slider hover effects
                ApplyHoverEffect(
                    Slider,
                    Library.CurrentTheme.Tertiary,
                    Library.CurrentTheme.Accent,
                    SliderTitle,
                    Library.CurrentTheme.Text,
                    Color3.fromRGB(255, 255, 255)
                )

                local SliderObj = {}

                function SliderObj:SetValue(value)
                    SetValue(value)
                end

                function SliderObj:GetValue()
                    return tonumber(SliderValue.Text)
                end

                return SliderObj
            end

            -- Dropdown Element
            function SectionObj:AddDropdown(options)
                options = options or {}
                options.Title = options.Title or "Dropdown"
                options.Items = options.Items or {}
                options.Default = options.Default or nil
                options.Callback = options.Callback or function() end

                local Dropdown = CreateInstance("Frame", {
                    Name = options.Title.."Dropdown",
                    BackgroundColor3 = Library.CurrentTheme.Tertiary,
                    BorderSizePixel = 0,
                    Size = UDim2.new(1, 0, 0, 36),
                    ClipsDescendants = true,
                    Parent = SectionContent
                })

                local DropdownCorner = CreateInstance("UICorner", {
                    CornerRadius = UDim.new(0, 6),
                    Parent = Dropdown
                })

                local DropdownTitle = CreateInstance("TextLabel", {
                    Name = "DropdownTitle",
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, -40, 0, 36),
                    Position = UDim2.new(0, 10, 0, 0),
                    Text = options.Title,
                    TextColor3 = Library.CurrentTheme.Text,
                    TextSize = 15,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Font = Enum.Font.Gotham,
                    Parent = Dropdown
                })

                local DropdownArrow = CreateInstance("ImageLabel", {
                    Name = "DropdownArrow",
                    BackgroundTransparency = 1,
                    Size = UDim2.new(0, 20, 0, 20),
                    Position = UDim2.new(1, -30, 0, 8),
                    Image = Icons.dropdown,
                    ImageColor3 = Library.CurrentTheme.TextDark,
                    Parent = Dropdown
                })

                local DropdownContent = CreateInstance("Frame", {
                    Name = "DropdownContent",
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    Size = UDim2.new(1, -20, 0, 0),
                    Position = UDim2.new(0, 10, 0, 40),
                    AutomaticSize = Enum.AutomaticSize.Y,
                    Parent = Dropdown
                })

                local DropdownListLayout = CreateInstance("UIListLayout", {
                    FillDirection = Enum.FillDirection.Vertical,
                    HorizontalAlignment = Enum.HorizontalAlignment.Center,
                    SortOrder = Enum.SortOrder.LayoutOrder,
                    Padding = UDim.new(0, 5),
                    Parent = DropdownContent
                })

                local DropdownPadding = CreateInstance("UIPadding", {
                    PaddingBottom = UDim.new(0, 5),
                    Parent = DropdownContent
                })

                local Selected = options.Default
                local Opened = false

                local function UpdateDropdown()
                    if Selected then
                        DropdownTitle.Text = options.Title .. ": " .. tostring(Selected)
                    else
                        DropdownTitle.Text = options.Title
                    end
                end

                local ToggleDropdown = ToggleElement(
                    Dropdown,
                    DropdownListLayout,
                    UDim2.new(1, 0, 0, 36),
                    UDim2.new(1, 0, 0, 36 + DropdownListLayout.AbsoluteContentSize.Y + 10),
                    DropdownArrow
                )

                Dropdown.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        ToggleDropdown()
                    end
                end)
                -- Create dropdown items
                for i, item in pairs(options.Items) do
                    local DropdownItem = CreateInstance("TextButton", {
                        Name = "DropdownItem",
                        BackgroundColor3 = Library.CurrentTheme.Secondary,
                        BorderSizePixel = 0,
                        Size = UDim2.new(1, 0, 0, 30),
                        Text = tostring(item),
                        TextColor3 = Library.CurrentTheme.Text,
                        TextSize = 14,
                        Font = Enum.Font.Gotham,
                        Parent = DropdownContent
                    })

                    local DropdownItemCorner = CreateInstance("UICorner", {
                        CornerRadius = UDim.new(0, 4),
                        Parent = DropdownItem
                    })

                    DropdownItem.MouseEnter:Connect(function()
                        CreateTween(DropdownItem, TweenInfo_Hover, {
                            BackgroundColor3 = Library.CurrentTheme.Accent
                        })
                    end)

                    DropdownItem.MouseLeave:Connect(function()
                        CreateTween(DropdownItem, TweenInfo_Hover, {
                            BackgroundColor3 = Library.CurrentTheme.Secondary
                        })
                    end)

                    DropdownItem.MouseButton1Click:Connect(function()
                        Selected = item
                        UpdateDropdown()
                        options.Callback(Selected)
                        ToggleDropdown()
                    end)
                end

                -- Update dropdown with default value
                UpdateDropdown()

                -- Toggle dropdown when clicked
                Dropdown.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        ToggleDropdown()
                    end
                end)

                -- Dropdown hover effects
                ApplyHoverEffect(
                    Dropdown,
                    Library.CurrentTheme.Tertiary,
                    Library.CurrentTheme.Accent,
                    DropdownTitle,
                    Library.CurrentTheme.Text,
                    Color3.fromRGB(255, 255, 255)
                )

                local DropdownObj = {}

                function DropdownObj:SetValue(value)
                    if table.find(options.Items, value) then
                        Selected = value
                        UpdateDropdown()
                        options.Callback(Selected)
                    end
                end

                function DropdownObj:GetValue()
                    return Selected
                end

                function DropdownObj:Refresh(items)
                    -- Clear existing items
                    for _, child in pairs(DropdownContent:GetChildren()) do
                        if child:IsA("TextButton") then
                            child:Destroy()
                        end
                    end

                    -- Update items list
                    options.Items = items

                    -- Recreate dropdown items
                    for i, item in pairs(options.Items) do
                        local DropdownItem = CreateInstance("TextButton", {
                            Name = "DropdownItem",
                            BackgroundColor3 = Library.CurrentTheme.Secondary,
                            BorderSizePixel = 0,
                            Size = UDim2.new(1, 0, 0, 30),
                            Text = tostring(item),
                            TextColor3 = Library.CurrentTheme.Text,
                            TextSize = 14,
                            Font = Enum.Font.Gotham,
                            Parent = DropdownContent
                        })

                        local DropdownItemCorner = CreateInstance("UICorner", {
                            CornerRadius = UDim.new(0, 4),
                            Parent = DropdownItem
                        })

                        DropdownItem.MouseEnter:Connect(function()
                            CreateTween(DropdownItem, TweenInfo_Hover, {
                                BackgroundColor3 = Library.CurrentTheme.Accent
                            })
                        end)

                        DropdownItem.MouseLeave:Connect(function()
                            CreateTween(DropdownItem, TweenInfo_Hover, {
                                BackgroundColor3 = Library.CurrentTheme.Secondary
                            })
                        end)

                        DropdownItem.MouseButton1Click:Connect(function()
                            Selected = item
                            UpdateDropdown()
                            options.Callback(Selected)
                            ToggleDropdown()
                        end)
                    end

                    -- Reset selected value if it's no longer in the items list
                    if not table.find(options.Items, Selected) then
                        Selected = nil
                        UpdateDropdown()
                    end

                    -- Update dropdown size if it's open
                    if Opened then
                        Dropdown.Size = UDim2.new(1, 0, 0, 36 + DropdownListLayout.AbsoluteContentSize.Y + 10)
                    end
                end

                return DropdownObj
            end

            -- ColorPicker Element
            function SectionObj:AddColorPicker(options)
                options = options or {}
                options.Title = options.Title or "ColorPicker"
                options.Default = options.Default or Color3.fromRGB(255, 255, 255)
                options.Callback = options.Callback or function() end

                local ColorPicker = CreateInstance("Frame", {
                    Name = options.Title.."ColorPicker",
                    BackgroundColor3 = Library.CurrentTheme.Tertiary,
                    BorderSizePixel = 0,
                    Size = UDim2.new(1, 0, 0, 36),
                    ClipsDescendants = true,
                    Parent = SectionContent
                })

                local ColorPickerCorner = CreateInstance("UICorner", {
                    CornerRadius = UDim.new(0, 6),
                    Parent = ColorPicker
                })

                local ColorPickerTitle = CreateInstance("TextLabel", {
                    Name = "ColorPickerTitle",
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, -60, 0, 36),
                    Position = UDim2.new(0, 10, 0, 0),
                    Text = options.Title,
                    TextColor3 = Library.CurrentTheme.Text,
                    TextSize = 15,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Font = Enum.Font.Gotham,
                    Parent = ColorPicker
                })

                local ColorDisplay = CreateInstance("Frame", {
                    Name = "ColorDisplay",
                    BackgroundColor3 = options.Default,
                    BorderSizePixel = 0,
                    Size = UDim2.new(0, 20, 0, 20),
                    Position = UDim2.new(1, -30, 0.5, -10),
                    Parent = ColorPicker
                })

                local ColorDisplayCorner = CreateInstance("UICorner", {
                    CornerRadius = UDim.new(0, 4),
                    Parent = ColorDisplay
                })

                local ColorPickerContent = CreateInstance("Frame", {
                    Name = "ColorPickerContent",
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    Size = UDim2.new(1, -20, 0, 0),
                    Position = UDim2.new(0, 10, 0, 40),
                    AutomaticSize = Enum.AutomaticSize.Y,
                    Parent = ColorPicker
                })

                local ColorPickerListLayout = CreateInstance("UIListLayout", {
                    FillDirection = Enum.FillDirection.Vertical,
                    HorizontalAlignment = Enum.HorizontalAlignment.Center,
                    SortOrder = Enum.SortOrder.LayoutOrder,
                    Padding = UDim.new(0, 5),
                    Parent = ColorPickerContent
                })

                local ColorPickerPadding = CreateInstance("UIPadding", {
                    PaddingBottom = UDim.new(0, 5),
                    Parent = ColorPickerContent
                })

                local Opened = false

                local function ToggleColorPicker()
                    Opened = not Opened

                    if Opened then
                        CreateTween(ColorPicker, TweenInfo_Notification, {
                            Size = UDim2.new(1, 0, 0, 36 + ColorPickerListLayout.AbsoluteContentSize.Y + 10)
                        })
                    else
                        CreateTween(ColorPicker, TweenInfo_Notification, {
                            Size = UDim2.new(1, 0, 0, 36)
                        })
                    end
                end

                -- Color Picker functionality
                local function UpdateColor(color)
                    ColorDisplay.BackgroundColor3 = color
                    options.Callback(color)
                end

                -- Create color picker elements
                local ColorSlider = CreateInstance("Frame", {
                    Name = "ColorSlider",
                    BackgroundColor3 = Library.CurrentTheme.Secondary,
                    BorderSizePixel = 0,
                    Size = UDim2.new(1, 0, 0, 20),
                    Parent = ColorPickerContent
                })

                local ColorSliderCorner = CreateInstance("UICorner", {
                    CornerRadius = UDim.new(0, 4),
                    Parent = ColorSlider
                })

                local ColorSliderGradient = CreateInstance("UIGradient", {
                    Color = ColorSequence.new({
                        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
                        ColorSequenceKeypoint.new(0.166, Color3.fromRGB(255, 255, 0)),
                        ColorSequenceKeypoint.new(0.333, Color3.fromRGB(0, 255, 0)),
                        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 255)),
                        ColorSequenceKeypoint.new(0.666, Color3.fromRGB(0, 0, 255)),
                        ColorSequenceKeypoint.new(0.833, Color3.fromRGB(255, 0, 255)),
                        ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0))
                    }),
                    Parent = ColorSlider
                })

                local ColorSliderDot = CreateInstance("Frame", {
                    Name = "ColorSliderDot",
                    BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                    BorderSizePixel = 0,
                    Size = UDim2.new(0, 8, 0, 8),
                    Position = UDim2.new(0.5, -4, 0.5, -4),
                    Parent = ColorSlider
                })

                local ColorSliderDotCorner = CreateInstance("UICorner", {
                    CornerRadius = UDim.new(1, 0),
                    Parent = ColorSliderDot
                })

                local function UpdateColorFromSlider(position)
                    local percent = math.clamp((position - ColorSlider.AbsolutePosition.X) / ColorSlider.AbsoluteSize.X, 0, 1)
                    local color = Color3.fromHSV(percent, 1, 1)
                    UpdateColor(color)
                end

                ColorSlider.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        UpdateColorFromSlider(input.Position.X)
                    end
                end)

                UserInputService.InputChanged:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseMovement and input.UserInputState == Enum.UserInputState.Change then
                        if ColorSlider:IsMouseOver() then
                            UpdateColorFromSlider(input.Position.X)
                        end
                    end
                end)

                -- Toggle color picker when clicked
                ColorPicker.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        ToggleColorPicker()
                    end
                end)

                -- Color Picker hover effects
                ApplyHoverEffect(
                    ColorPicker,
                    Library.CurrentTheme.Tertiary,
                    Library.CurrentTheme.Accent,
                    ColorPickerTitle,
                    Library.CurrentTheme.Text,
                    Color3.fromRGB(255, 255, 255)
                )

                local ColorPickerObj = {}

                function ColorPickerObj:SetColor(color)
                    UpdateColor(color)
                end

                function ColorPickerObj:GetColor()
                    return ColorDisplay.BackgroundColor3
                end

                return ColorPickerObj
            end

            -- Return Section Object
            return SectionObj
        end

        -- Return Tab Object
        return TabObj
    end

    -- Window Functions
    function Window:SelectTab(tabName)
        SelectTab(tabName, Window.Tabs, Library.CurrentTheme)
    end

    function Window:Destroy()
        MainGui:Destroy()
        Library.Unloaded = true
    end

    return Window
end

-- Return Library
return Library
