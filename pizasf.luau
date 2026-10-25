-- Script taken from https://xenoscripts.com website --

-- NOVA SIMPLE ALL-IN-ONE | Xeno
-- ESP + Head Expand + Round Team + Wallbang
-- RightShift = GUI | Delete = unload

local ENV = getgenv()

if ENV.NovaSimple and ENV.NovaSimple.Unload then
    pcall(ENV.NovaSimple.Unload)
end

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")

local LP = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local CFG = {
    TeamCheck = true,
    TeamRadius = 30,

    ESP = true,
    Highlight = true,
    HeadBox = true,
    Name = true,
    Health = true,
    Distance = true,
    MaxDistance = 2500,

    HeadExpand = false,
    HeadSize = 6,
    HeadTransparency = 0.55,

    Wallbang = false,
    PenetrationDepth = 3,

    Particles = true,
}

local running = true
local connections = {}

local ESP = {}
local originalHeads = {}
local roundTeam = {}

local roundActive = false
local roundEndedAt = 0
local roundNumber = 0

--------------------------------------------------
-- CONNECTIONS
--------------------------------------------------

local function connect(signal, callback)
    local c = signal:Connect(callback)
    connections[#connections + 1] = c
    return c
end

--------------------------------------------------
-- PLAYER
--------------------------------------------------

local function getRoot(player)
    local c = player and player.Character
    if not c then return nil end

    return c:FindFirstChild("HumanoidRootPart")
        or c:FindFirstChild("UpperTorso")
        or c:FindFirstChild("Torso")
end

local function getHumanoid(player)
    local c = player and player.Character
    return c and c:FindFirstChildOfClass("Humanoid")
end

local function getHP(player)
    local c = player and player.Character
    if not c then return 0 end

    local hum = c:FindFirstChildOfClass("Humanoid")

    if hum then
        return hum.Health
    end

    local hp =
        c:GetAttribute("Health")
        or c:GetAttribute("HP")

    if typeof(hp) == "number" then
        return hp
    end

    return getRoot(player) and 100 or 0
end

local function alive(player)
    return getHP(player) > 0
end

--------------------------------------------------
-- TEAM
--------------------------------------------------

local function standardTeammate(a,b)
    if not a or not b then return false end

    if a.Team and b.Team then
        return a.Team == b.Team
    end

    if not a.Neutral
        and not b.Neutral
        and a.TeamColor
        and b.TeamColor then

        return a.TeamColor == b.TeamColor
    end

    for _, key in ipairs({
        "Team",
        "TeamId",
        "TeamID",
        "Side",
        "Faction"
    }) do
        local x = a:GetAttribute(key)
        local y = b:GetAttribute(key)

        if x ~= nil and y ~= nil then
            return tostring(x) == tostring(y)
        end
    end

    return false
end

local function teammate(player)
    if player == LP then return true end

    if standardTeammate(LP,player) then
        return true
    end

    return roundTeam[player] == true
end

local function validTarget(player)
    if player == LP then return false end
    if not alive(player) then return false end

    if CFG.TeamCheck and teammate(player) then
        return false
    end

    return true
end

--------------------------------------------------
-- THEME
--------------------------------------------------

local T = {
    Background = Color3.fromRGB(13,13,18),
    Window = Color3.fromRGB(18,18,26),
    Card = Color3.fromRGB(26,26,37),
    Border = Color3.fromRGB(40,40,58),

    Text = Color3.fromRGB(230,230,240),
    Dim = Color3.fromRGB(140,140,162),

    Accent = Color3.fromRGB(0,195,255),
    Accent2 = Color3.fromRGB(150,75,255),

    Red = Color3.fromRGB(255,70,85),
    Yellow = Color3.fromRGB(255,215,60),

    White = Color3.new(1,1,1),
}

local function new(class, props)
    local o = Instance.new(class)

    for k,v in pairs(props or {}) do
        if k ~= "Parent" then
            o[k] = v
        end
    end

    if props and props.Parent then
        o.Parent = props.Parent
    end

    return o
end

local function corner(parent,r)
    return new("UICorner",{
        CornerRadius = UDim.new(0,r or 7),
        Parent = parent,
    })
end

local function stroke(parent)
    return new("UIStroke",{
        Color = T.Border,
        Thickness = 1,
        Transparency = 0.25,
        Parent = parent,
    })
end

local function tween(object,props,duration)
    local t = TweenService:Create(
        object,
        TweenInfo.new(
            duration or 0.16,
            Enum.EasingStyle.Quint,
            Enum.EasingDirection.Out
        ),
        props
    )

    t:Play()
    return t
end

--------------------------------------------------
-- GUI ROOT
--------------------------------------------------

local gui = new("ScreenGui",{
    Name = "NovaSimple_"..math.random(1000,9999),
    ResetOnSpawn = false,
    IgnoreGuiInset = true,
    DisplayOrder = 999999,
})

local mounted = false

if gethui then
    local ok,parent = pcall(gethui)

    if ok and parent then
        gui.Parent = parent
        mounted = true
    end
end

if not mounted then
    local ok = pcall(function()
        gui.Parent = CoreGui
    end)

    if not ok then
        gui.Parent = LP:WaitForChild("PlayerGui")
    end
end

local window = new("Frame",{
    Size = UDim2.fromOffset(370,530),
    Position = UDim2.new(0,30,0.5,-265),

    BackgroundColor3 = T.Window,

    BorderSizePixel = 0,
    ClipsDescendants = true,

    Parent = gui,
})

corner(window,11)
stroke(window)

--------------------------------------------------
-- PARTICLES
--------------------------------------------------

local particleLayer = new("Frame",{
    Size = UDim2.fromScale(1,1),
    BackgroundTransparency = 1,
    Parent = window,
})

local particles = {}

for i=1,20 do
    local size = math.random(2,3)

    local object = new("Frame",{
        Size = UDim2.fromOffset(size,size),

        Position = UDim2.fromScale(
            math.random(),
            math.random()
        ),

        BackgroundColor3 =
            i%2==0 and T.Accent or T.Accent2,

        BackgroundTransparency = 0.6,
        BorderSizePixel = 0,

        Parent = particleLayer,
    })

    corner(object,size)

    local angle = math.random()*math.pi*2

    particles[#particles+1] = {
        Object = object,
        X = math.cos(angle),
        Y = math.sin(angle),
    }
end

connect(RunService.RenderStepped,function(dt)
    if not CFG.Particles then
        particleLayer.Visible=false
        return
    end

    particleLayer.Visible=true

    local size=window.AbsoluteSize

    if size.X<=0 or size.Y<=0 then
        return
    end

    for _,p in ipairs(particles) do
        local old=p.Object.Position

        local x=
            old.X.Scale
            + p.X*dt*5/size.X

        local y=
            old.Y.Scale
            + p.Y*dt*5/size.Y

        if x<0 then x=1
        elseif x>1 then x=0 end

        if y<0 then y=1
        elseif y>1 then y=0 end

        p.Object.Position=
            UDim2.fromScale(x,y)
    end
end)

--------------------------------------------------
-- HEADER
--------------------------------------------------

local header = new("Frame",{
    Size=UDim2.new(1,0,0,52),
    BackgroundColor3=T.Background,
    BorderSizePixel=0,
    ZIndex=10,
    Parent=window,
})

new("TextLabel",{
    Position=UDim2.fromOffset(15,6),
    Size=UDim2.new(1,-100,0,23),

    BackgroundTransparency=1,

    Text="NOVA SIMPLE",
    TextColor3=T.Text,

    Font=Enum.Font.GothamBlack,
    TextSize=16,

    TextXAlignment=
        Enum.TextXAlignment.Left,

    ZIndex=11,

    Parent=header,
})

new("TextLabel",{
    Position=UDim2.fromOffset(15,27),
    Size=UDim2.new(1,-100,0,16),

    BackgroundTransparency=1,

    Text="ESP • HEAD • ROUND TEAM • WALLBANG",

    TextColor3=T.Dim,

    Font=Enum.Font.Gotham,
    TextSize=9,

    TextXAlignment=
        Enum.TextXAlignment.Left,

    ZIndex=11,

    Parent=header,
})

--------------------------------------------------
-- MIN / CLOSE
--------------------------------------------------

local minimize = new("TextButton",{
    Position=UDim2.new(1,-74,0,11),
    Size=UDim2.fromOffset(28,28),

    BackgroundColor3=T.Card,
    BorderSizePixel=0,

    Text="—",
    TextColor3=T.Dim,

    Font=Enum.Font.GothamBold,
    TextSize=15,

    AutoButtonColor=false,

    ZIndex=12,
    Parent=header,
})

corner(minimize,7)

local close = new("TextButton",{
    Position=UDim2.new(1,-40,0,11),
    Size=UDim2.fromOffset(28,28),

    BackgroundColor3=T.Card,
    BorderSizePixel=0,

    Text="×",
    TextColor3=T.Dim,

    Font=Enum.Font.GothamBold,
    TextSize=17,

    AutoButtonColor=false,

    ZIndex=12,
    Parent=header,
})

corner(close,7)

--------------------------------------------------
-- CONTENT
--------------------------------------------------

local content = new("ScrollingFrame",{
    Position=UDim2.fromOffset(8,60),
    Size=UDim2.new(1,-16,1,-68),

    BackgroundTransparency=1,
    BorderSizePixel=0,

    ScrollBarThickness=3,
    ScrollBarImageColor3=T.Accent,

    CanvasSize=UDim2.new(),

    AutomaticCanvasSize=
        Enum.AutomaticSize.Y,

    Parent=window,
})

new("UIListLayout",{
    Padding=UDim.new(0,6),

    HorizontalAlignment=
        Enum.HorizontalAlignment.Center,

    Parent=content,
})

--------------------------------------------------
-- WIDGETS
--------------------------------------------------

local function section(text)
    return new("TextLabel",{
        Size=UDim2.new(1,-6,0,27),

        BackgroundTransparency=1,

        Text=text,

        TextColor3=T.Accent,

        Font=Enum.Font.GothamBold,
        TextSize=12,

        TextXAlignment=
            Enum.TextXAlignment.Left,

        Parent=content,
    })
end

local function toggle(name,key,callback)
    local holder=new("Frame",{
        Size=UDim2.new(1,-6,0,40),

        BackgroundColor3=T.Card,

        BorderSizePixel=0,

        Parent=content,
    })

    corner(holder,7)
    stroke(holder)

    new("TextLabel",{
        Position=UDim2.fromOffset(11,0),
        Size=UDim2.new(1,-65,1,0),

        BackgroundTransparency=1,

        Text=name,

        TextColor3=T.Text,

        Font=Enum.Font.GothamMedium,
        TextSize=12,

        TextXAlignment=
            Enum.TextXAlignment.Left,

        Parent=holder,
    })

    local track=new("Frame",{
        Position=UDim2.new(1,-45,0.5,-9),

        Size=UDim2.fromOffset(32,18),

        BorderSizePixel=0,

        Parent=holder,
    })

    corner(track,10)

    local knob=new("Frame",{
        Size=UDim2.fromOffset(12,12),

        BackgroundColor3=T.White,

        BorderSizePixel=0,

        Parent=track,
    })

    corner(knob,7)

    local function paint()
        local state=CFG[key]==true

        tween(track,{
            BackgroundColor3=
                state
                and T.Accent
                or Color3.fromRGB(52,52,66),
        })

        tween(knob,{
            Position=
                state
                and UDim2.new(1,-15,0.5,-6)
                or UDim2.new(0,3,0.5,-6),
        })
    end

    local click=new("TextButton",{
        Size=UDim2.fromScale(1,1),

        BackgroundTransparency=1,

        Text="",

        Parent=holder,
    })

    click.MouseButton1Click:Connect(function()
        CFG[key]=not CFG[key]

        paint()

        if callback then
            callback(CFG[key])
        end
    end)

    paint()
end

local function slider(
    name,key,mn,mx,step
)
    local holder=new("Frame",{
        Size=UDim2.new(1,-6,0,56),

        BackgroundColor3=T.Card,

        BorderSizePixel=0,

        Parent=content,
    })

    corner(holder,7)
    stroke(holder)

    local label=new("TextLabel",{
        Position=UDim2.fromOffset(11,2),
        Size=UDim2.new(1,-22,0,25),

        BackgroundTransparency=1,

        TextColor3=T.Text,

        Font=Enum.Font.Gotham,
        TextSize=12,

        TextXAlignment=
            Enum.TextXAlignment.Left,

        Parent=holder,
    })

    local track=new("Frame",{
        Position=UDim2.new(0,11,1,-16),

        Size=UDim2.new(1,-22,0,5),

        BackgroundColor3=
            Color3.fromRGB(52,52,66),

        BorderSizePixel=0,

        Parent=holder,
    })

    corner(track,3)

    local fill=new("Frame",{
        BackgroundColor3=T.Accent,
        BorderSizePixel=0,
        Parent=track,
    })

    corner(fill,3)

    local dragging=false

    local function set(value)
        value=math.clamp(
            value,
            mn,
            mx
        )

        value=
            math.floor(
                value/step+0.5
            )*step

        value=tonumber(
            string.format(
                "%.3f",
                value
            )
        )

        CFG[key]=value

        local ratio=
            (value-mn)/(mx-mn)

        fill.Size=
            UDim2.fromScale(
                ratio,
                1
            )

        if step<1 then
            label.Text=
                name..": "..
                string.format(
                    "%.2f",
                    value
                )
        else
            label.Text=
                name..": "..
                tostring(
                    math.floor(value)
                )
        end
    end

    local function update(x)
        if track.AbsoluteSize.X<=0 then
            return
        end

        local ratio=
            math.clamp(
                (x-track.AbsolutePosition.X)
                /track.AbsoluteSize.X,
                0,
                1
            )

        set(
            mn+(mx-mn)*ratio
        )
    end

    connect(track.InputBegan,function(i)
        if i.UserInputType==
            Enum.UserInputType.MouseButton1 then

            dragging=true
            update(i.Position.X)
        end
    end)

    connect(UIS.InputChanged,function(i)
        if dragging
            and i.UserInputType==
                Enum.UserInputType.MouseMovement then

            update(i.Position.X)
        end
    end)

    connect(UIS.InputEnded,function(i)
        if i.UserInputType==
            Enum.UserInputType.MouseButton1 then

            dragging=false
        end
    end)

    set(CFG[key])
end

--------------------------------------------------
-- HEAD RESTORE
--------------------------------------------------

local function restoreOneHead(head)
    local o=originalHeads[head]

    if not o then
        return
    end

    originalHeads[head]=nil

    if not head.Parent then
        return
    end

    pcall(function()
        head.Size=o.Size

        head.Transparency=
            o.Transparency

        head.CanCollide=
            o.CanCollide

        head.Massless=
            o.Massless
    end)
end

local function restoreHeads()
    local list={}

    for head in pairs(originalHeads) do
        list[#list+1]=head
    end

    for _,head in ipairs(list) do
        restoreOneHead(head)
    end
end

--------------------------------------------------
-- ESP
--------------------------------------------------

local function hideESP(d)
    if not d then return end

    d.Highlight.Enabled=false
    d.HeadBox.Visible=false
    d.Gui.Enabled=false
end

local function removeESP(player)
    local d=ESP[player]

    if not d then return end

    pcall(function()
        d.Highlight:Destroy()
    end)

    pcall(function()
        d.HeadBox:Destroy()
    end)

    pcall(function()
        d.Gui:Destroy()
    end)

    ESP[player]=nil
end

local function createESP(player)
    removeESP(player)

    if player==LP then
        return
    end

    local char=player.Character

    if not char then
        return
    end

    local head=
        char:FindFirstChild("Head")

    if not head then
        return
    end

    local highlight=new("Highlight",{
        Adornee=char,

        DepthMode=
            Enum.HighlightDepthMode.AlwaysOnTop,

        FillColor=T.Red,
        OutlineColor=T.Red,

        FillTransparency=0.75,

        Enabled=false,

        Parent=char,
    })

    local box=new("BoxHandleAdornment",{
        Adornee=head,

        AlwaysOnTop=true,

        ZIndex=10,

        Size=head.Size,

        Color3=T.Yellow,

        Transparency=0.55,

        Visible=false,

        Parent=head,
    })

    local bill=new("BillboardGui",{
        Adornee=head,

        Size=UDim2.fromOffset(260,40),

        StudsOffset=
            Vector3.new(0,2.7,0),

        AlwaysOnTop=true,

        Enabled=false,

        Parent=head,
    })

    local text=new("TextLabel",{
        Size=UDim2.fromScale(1,1),

        BackgroundTransparency=1,

        TextColor3=T.Red,

        TextStrokeTransparency=0,

        Font=Enum.Font.GothamBold,

        TextSize=13,

        Parent=bill,
    })

    ESP[player]={
        Head=head,

        Highlight=highlight,

        HeadBox=box,

        Gui=bill,

        Text=text,
    }
end

--------------------------------------------------
-- HEALTH WATCH
--------------------------------------------------

local function watchHealth(player,char)
    local hum=
        char:FindFirstChildOfClass(
            "Humanoid"
        )

    if not hum then
        hum=char:WaitForChild(
            "Humanoid",
            3
        )
    end

    if not hum then
        return
    end

    connect(
        hum.HealthChanged,
        function(hp)
            if hp>0 then
                return
            end

            hideESP(ESP[player])

            local head=
                char:FindFirstChild(
                    "Head"
                )

            if head then
                restoreOneHead(head)
            end
        end
    )
end

--------------------------------------------------
-- PLAYER HOOK
--------------------------------------------------

local function hookPlayer(player)
    if player==LP then
        return
    end

    connect(
        player.CharacterAdded,
        function(char)
            task.wait(0.3)

            if not running then
                return
            end

            createESP(player)

            task.spawn(
                watchHealth,
                player,
                char
            )
        end
    )

    connect(
        player.CharacterRemoving,
        function()
            removeESP(player)

            roundTeam[player]=nil
        end
    )

    if player.Character then
        createESP(player)

        task.spawn(
            watchHealth,
            player,
            player.Character
        )
    end
end

for _,p in ipairs(
    Players:GetPlayers()
) do
    hookPlayer(p)
end

connect(
    Players.PlayerAdded,
    hookPlayer
)

connect(
    Players.PlayerRemoving,
    function(p)
        removeESP(p)
        roundTeam[p]=nil
    end
)

--------------------------------------------------
-- ROUND TEAM
--------------------------------------------------

local function clearRoundTeam()
    table.clear(roundTeam)
end

local function rebuildRoundTeam()
    clearRoundTeam()

    local myRoot=getRoot(LP)

    if not myRoot or not alive(LP) then
        return
    end

    local count=0

    for _,p in ipairs(
        Players:GetPlayers()
    ) do
        if p~=LP and alive(p) then
            local root=getRoot(p)

            if root then
                local distance=
                    (
                        root.Position
                        - myRoot.Position
                    ).Magnitude

                if distance<=CFG.TeamRadius then
                    roundTeam[p]=true
                    count+=1
                end
            end
        end
    end

    roundNumber+=1

    print(
        "[NOVA] round #"
        ..roundNumber
        .." team="
        ..count
    )
end

--------------------------------------------------
-- ROUND DETECTOR
--------------------------------------------------

local roundAcc=0

connect(RunService.Heartbeat,function(dt)
    roundAcc+=dt

    if roundAcc<0.5 then
        return
    end

    roundAcc=0

    local count=0

    for _,p in ipairs(
        Players:GetPlayers()
    ) do
        if alive(p) then
            count+=1
        end
    end

    local meAlive=alive(LP)

    if roundActive then
        if not meAlive or count<=1 then
            roundActive=false

            roundEndedAt=os.clock()

            clearRoundTeam()
        end
    else
        if meAlive
            and count>=2
            and os.clock()-roundEndedAt>=1 then

            roundActive=true

            task.delay(0.8,function()
                if running
                    and roundActive
                    and alive(LP) then

                    rebuildRoundTeam()
                end
            end)
        end
    end
end)

--------------------------------------------------
-- HEAD EXPAND
--------------------------------------------------

local function updateHeads()
    local wanted=Vector3.new(
        CFG.HeadSize,
        CFG.HeadSize,
        CFG.HeadSize
    )

    local valid={}

    for _,p in ipairs(
        Players:GetPlayers()
    ) do
        if validTarget(p) then
            local char=p.Character

            local head=
                char
                and char:FindFirstChild(
                    "Head"
                )

            if head
                and head:IsA("BasePart") then

                valid[head]=true

                if not originalHeads[head] then
                    originalHeads[head]={
                        Size=head.Size,

                        Transparency=
                            head.Transparency,

                        CanCollide=
                            head.CanCollide,

                        Massless=
                            head.Massless,
                    }
                end

                pcall(function()
                    head.Size=wanted

                    head.Transparency=
                        CFG.HeadTransparency

                    head.CanCollide=false
                    head.Massless=true
                end)
            end
        end
    end

    local restore={}

    for head in pairs(
        originalHeads
    ) do
        if not valid[head] then
            restore[#restore+1]=head
        end
    end

    for _,head in ipairs(restore) do
        restoreOneHead(head)
    end
end

--------------------------------------------------
-- CLIENT WALLBANG
--------------------------------------------------

local wallRestore={}
local wallBusy=false

local wallParams=
    RaycastParams.new()

wallParams.FilterType=
    Enum.RaycastFilterType.Exclude

wallParams.IgnoreWater=true

local function characterPart(part)
    if not part then
        return false
    end

    local model=
        part:FindFirstAncestorOfClass(
            "Model"
        )

    if not model then
        return false
    end

    if Players:GetPlayerFromCharacter(model) then
        return true
    end

    return model:FindFirstChildOfClass(
        "Humanoid"
    )~=nil
end

local function rememberWall(part)
    if wallRestore[part] then
        return
    end

    wallRestore[part]={
        CanQuery=part.CanQuery,

        LocalTransparencyModifier=
            part.LocalTransparencyModifier,
    }
end

local function restoreWalls()
    local list={}

    for part in pairs(wallRestore) do
        list[#list+1]=part
    end

    for _,part in ipairs(list) do
        local old=wallRestore[part]

        wallRestore[part]=nil

        if part and part.Parent then
            pcall(function()
                part.CanQuery=
                    old.CanQuery

                part.LocalTransparencyModifier=
                    old.LocalTransparencyModifier
            end)
        end
    end
end

local function prepareWallbang()
    if wallBusy or not CFG.Wallbang then
        return
    end

    Camera=workspace.CurrentCamera

    if not Camera then
        return
    end

    wallBusy=true

    local vp=Camera.ViewportSize

    local ray=
        Camera:ViewportPointToRay(
            vp.X*0.5,
            vp.Y*0.5
        )

    local ignored={}

    if LP.Character then
        ignored[1]=LP.Character
    end

    local origin=ray.Origin

    local direction=
        ray.Direction*5000

    for _=1,CFG.PenetrationDepth do
        wallParams.FilterDescendantsInstances=
            ignored

        local hit=
            workspace:Raycast(
                origin,
                direction,
                wallParams
            )

        if not hit or not hit.Instance then
            break
        end

        local part=hit.Instance

        if characterPart(part) then
            break
        end

        if part:IsA("BasePart") then
            rememberWall(part)

            pcall(function()
                part.CanQuery=false

                part.LocalTransparencyModifier=
                    math.max(
                        part.LocalTransparencyModifier,
                        0.6
                    )
            end)
        end

        ignored[#ignored+1]=part
    end

    task.delay(0.08,function()
        restoreWalls()
        wallBusy=false
    end)
end

--------------------------------------------------
-- ESP + HEAD UPDATE
--------------------------------------------------

local updateAcc=0

connect(RunService.Heartbeat,function(dt)
    if not running then return end

    updateAcc+=dt

    if updateAcc<0.08 then
        return
    end

    updateAcc=0

    Camera=workspace.CurrentCamera

    if not Camera then return end

    if CFG.HeadExpand then
        updateHeads()
    elseif next(originalHeads) then
        restoreHeads()
    end

    local camPos=
        Camera.CFrame.Position

    for _,p in ipairs(
        Players:GetPlayers()
    ) do
        if p~=LP then
            local char=p.Character

            local head=
                char
                and char:FindFirstChild(
                    "Head"
                )

            local root=getRoot(p)

            if head and root then
                local d=ESP[p]

                if not d or d.Head~=head then
                    createESP(p)
                    d=ESP[p]
                end

                if d then
                    local distance=
                        (
                            root.Position
                            - camPos
                        ).Magnitude

                    local show=
                        CFG.ESP
                        and validTarget(p)
                        and distance<=
                            CFG.MaxDistance

                    if show then
                        d.Highlight.Enabled=
                            CFG.Highlight

                        d.HeadBox.Visible=
                            CFG.HeadBox

                        d.HeadBox.Size=
                            head.Size

                        local pieces={}

                        if CFG.Name then
                            pieces[#pieces+1]=
                                p.DisplayName
                        end

                        if CFG.Health then
                            pieces[#pieces+1]=
                                math.floor(
                                    getHP(p)
                                ).." HP"
                        end

                        if CFG.Distance then
                            pieces[#pieces+1]=
                                math.floor(
                                    distance
                                ).."m"
                        end

                        d.Gui.Enabled=
                            #pieces>0

                        d.Text.Text=
                            table.concat(
                                pieces,
                                " | "
                            )
                    else
                        hideESP(d)
                    end
                end
            elseif ESP[p] then
                hideESP(ESP[p])
            end
        end
    end
end)

--------------------------------------------------
-- GUI ITEMS
--------------------------------------------------

section("TEAM / ROUND")

toggle(
    "Team Check",
    "TeamCheck",

    function()
        if CFG.TeamCheck then
            for _,p in ipairs(
                Players:GetPlayers()
            ) do
                if teammate(p) then
                    hideESP(ESP[p])

                    local ch=p.Character

                    local head=
                        ch
                        and ch:FindFirstChild(
                            "Head"
                        )

                    if head then
                        restoreOneHead(head)
                    end
                end
            end
        end
    end
)

slider(
    "Spawn Team Radius",
    "TeamRadius",
    5,
    60,
    1
)

section("ESP")

toggle("ESP","ESP")
toggle("Подсветка","Highlight")
toggle("Бокс головы","HeadBox")
toggle("Имя","Name")
toggle("HP","Health")
toggle("Дистанция","Distance")

slider(
    "Дальность ESP",
    "MaxDistance",
    100,
    5000,
    100
)

section("HEAD HITBOX")

toggle(
    "Увеличение головы",
    "HeadExpand",

    function(v)
        if not v then
            restoreHeads()
        end
    end
)

slider(
    "Размер головы",
    "HeadSize",
    1,
    30,
    0.5
)

slider(
    "Прозрачность",
    "HeadTransparency",
    0,
    1,
    0.05
)

section("WALLBANG")

toggle(
    "Client Wallbang",
    "Wallbang",

    function(v)
        if not v then
            restoreWalls()
        end
    end
)

slider(
    "Глубина прострела",
    "PenetrationDepth",
    1,
    6,
    1
)

section("GUI")

toggle("Частицы","Particles")

--------------------------------------------------
-- INPUT
--------------------------------------------------

connect(UIS.InputBegan,function(input,processed)
    -- Делается до processed, чтобы оружейный ввод
    -- мог произойти в том же кадре.
    if input.UserInputType==
        Enum.UserInputType.MouseButton1
        and CFG.Wallbang then

        prepareWallbang()
    end

    if processed then return end

    if input.KeyCode==
        Enum.KeyCode.RightShift then

        window.Visible=
            not window.Visible

    elseif input.KeyCode==
        Enum.KeyCode.Delete then

        if ENV.NovaSimple
            and ENV.NovaSimple.Unload then

            task.defer(
                ENV.NovaSimple.Unload
            )
        end
    end
end)

--------------------------------------------------
-- MINIMIZE
--------------------------------------------------

local minimized=false
local normalHeight=530

minimize.MouseButton1Click:Connect(function()
    minimized=not minimized

    if minimized then
        normalHeight=
            window.Size.Y.Offset

        content.Visible=false
        particleLayer.Visible=false

        minimize.Text="+"

        tween(
            window,
            {
                Size=
                    UDim2.fromOffset(
                        window.Size.X.Offset,
                        52
                    )
            },
            0.2
        )
    else
        minimize.Text="—"

        tween(
            window,
            {
                Size=
                    UDim2.fromOffset(
                        window.Size.X.Offset,
                        normalHeight
                    )
            },
            0.2
        )

        task.delay(0.2,function()
            if running and not minimized then
                content.Visible=true
                particleLayer.Visible=
                    CFG.Particles
            end
        end)
    end
end)

--------------------------------------------------
-- DRAG
--------------------------------------------------

local dragging=false
local dragStart
local startPos

connect(header.InputBegan,function(i)
    if i.UserInputType==
        Enum.UserInputType.MouseButton1 then

        dragging=true

        dragStart=i.Position
        startPos=window.Position
    end
end)

connect(UIS.InputChanged,function(i)
    if dragging
        and i.UserInputType==
            Enum.UserInputType.MouseMovement then

        local d=
            i.Position-dragStart

        window.Position=
            UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset+d.X,
                startPos.Y.Scale,
                startPos.Y.Offset+d.Y
            )
    end
end)

connect(UIS.InputEnded,function(i)
    if i.UserInputType==
        Enum.UserInputType.MouseButton1 then

        dragging=false
    end
end)

--------------------------------------------------
-- UNLOAD
--------------------------------------------------

local unloading=false

local function unload()
    if unloading then return end

    unloading=true
    running=false

    restoreHeads()
    restoreWalls()
    clearRoundTeam()

    for _,c in ipairs(connections) do
        pcall(function()
            c:Disconnect()
        end)
    end

    for p in pairs(ESP) do
        removeESP(p)
    end

    pcall(function()
        gui:Destroy()
    end)

    ENV.NovaSimple=nil

    print("[NOVA] unloaded")
end

close.MouseButton1Click:Connect(unload)

ENV.NovaSimple={
    Config=CFG,
    Unload=unload,
    RebuildTeam=rebuildRoundTeam,
    IsTeammate=teammate,
    IsTarget=validTarget,
}

print(
    "[NOVA] loaded | "
    .."RightShift GUI | "
    .."Delete unload"
)