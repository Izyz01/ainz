-- Public entry point. GitHub credentials stay on the release host.
local HOST='https://ainz-release-host.dfcis-suggestion-box.workers.dev'
local env=getgenv()
local Players=game:GetService('Players')
local player=Players.LocalPlayer
while not player do Players:GetPropertyChangedSignal('LocalPlayer'):Wait();player=Players.LocalPlayer end
local robloxUserId=tostring(player.UserId)
local Http=game:GetService('HttpService')
local keyFile='AINZ-access-key-'..robloxUserId..'.json'
assert(not HOST:find('YOUR%-WORKER'),'AINZ release host has not been configured.')
assert(not env.AINZOnlineLoaderBusy,'AINZ is already downloading.')
local send=request or http_request or (type(syn)=='table' and syn.request)
assert(type(send)=='function','AINZ requires an executor with HTTP request headers.')
for _,item in ipairs({{'readfile',readfile},{'writefile',writefile},{'isfolder',isfolder},{'makefolder',makefolder},{'loadstring',loadstring}})do
 assert(type(item[2])=='function','AINZ requires '..item[1]..'.')
end
local asset=getcustomasset or getsynasset
assert(type(asset)=='function','AINZ requires custom image asset support.')
local function fetch(path,key)
 local ok,response=pcall(send,{Url=HOST..path,Method='GET',Headers=key and {Authorization='Bearer '..key,['X-Roblox-UserId']=robloxUserId} or {}})
 if not ok or type(response)~='table' then return nil,'Cannot connect to AINZ. Try again.' end
 local status=tonumber(response.StatusCode or response.Status)
 if status==401 then return nil,'Invalid or revoked key.',status end
 if status==403 then return nil,'This access key has expired.',status end
 if status==409 then return nil,'This key is already linked to another Roblox account.',status end
 if status==429 then return nil,'Too many requests. Wait one minute and try again.',status end
 if status~=200 or type(response.Body)~='string' or #response.Body==0 then return nil,'AINZ download unavailable. Try again later.' end
 return response.Body
end
local function png(body)
 return body:sub(1,8)==string.char(137,80,78,71,13,10,26,10)
end
local dialog
local function requestKey()
 local logo,reason=fetch('/brand')
 assert(logo,reason);assert(png(logo),'AINZ logo download is invalid.')
 writefile('ainz.png',logo)
 local image=asset('ainz.png');env.AINZIconAsset=image
 local function make(class,parent,props)
  local object=Instance.new(class);for k,v in pairs(props)do object[k]=v end;object.Parent=parent;return object
 end
 dialog=make('ScreenGui',game:GetService('CoreGui'),{Name='AINZAccessKey',ResetOnSpawn=false,DisplayOrder=10010,ScreenInsets=Enum.ScreenInsets.CoreUISafeInsets})
 local panel=make('Frame',dialog,{Size=UDim2.fromOffset(380,330),AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),BackgroundColor3=Color3.fromRGB(23,20,31),BorderSizePixel=0})
 make('UICorner',panel,{CornerRadius=UDim.new(0,14)})
 local scale=make('UIScale',panel,{Scale=1})
 local function fit()local size=dialog.AbsoluteSize;scale.Scale=math.min(1,math.max(1,size.X-24)/380,math.max(1,size.Y-24)/330)end
 local resize=dialog:GetPropertyChangedSignal('AbsoluteSize'):Connect(fit);fit()
 dialog.Destroying:Connect(function()resize:Disconnect()end)
 make('ImageLabel',panel,{Name='AINZIcon',Image=image,ScaleType=Enum.ScaleType.Fit,BackgroundTransparency=1,Size=UDim2.fromOffset(120,100),Position=UDim2.new(.5,-60,0,12)})
 local function label(text,y,height)
  return make('TextLabel',panel,{Text=text,BackgroundTransparency=1,Position=UDim2.fromOffset(22,y),Size=UDim2.new(1,-44,0,height),Font=Enum.Font.BuilderSans,TextSize=14,TextColor3=Color3.fromRGB(230,220,245),TextWrapped=true})
 end
 label('All I Need Z',112,24).Font=Enum.Font.BuilderSansBold
 label('Redeem for '..player.Name..' · '..robloxUserId,140,24)
 local box=make('TextBox',panel,{Text='',PlaceholderText='Access key',ClearTextOnFocus=false,MultiLine=false,Position=UDim2.fromOffset(22,176),Size=UDim2.new(1,-44,0,38),BackgroundColor3=Color3.fromRGB(39,32,51),TextColor3=Color3.new(1,1,1),PlaceholderColor3=Color3.fromRGB(164,148,181),Font=Enum.Font.BuilderSans,TextSize=14,BorderSizePixel=0})
 make('UICorner',box,{CornerRadius=UDim.new(0,7)})
 local status=label('',218,38)
 local open=make('TextButton',panel,{Text='Unlock AINZ',Position=UDim2.fromOffset(22,270),Size=UDim2.fromOffset(216,38),BackgroundColor3=Color3.fromRGB(113,67,159),TextColor3=Color3.new(1,1,1),Font=Enum.Font.BuilderSansBold,TextSize=14,BorderSizePixel=0})
 make('UICorner',open,{CornerRadius=UDim.new(0,7)})
 local cancel=make('TextButton',panel,{Text='Cancel',Position=UDim2.fromOffset(250,270),Size=UDim2.fromOffset(108,38),BackgroundColor3=Color3.fromRGB(39,32,51),TextColor3=Color3.fromRGB(230,220,245),Font=Enum.Font.BuilderSans,TextSize=14,BorderSizePixel=0})
 make('UICorner',cancel,{CornerRadius=UDim.new(0,7)})
 local key,bundle,cancelled,busy
 local function submit()
  if busy or cancelled then return end
  local candidate=box.Text:match('^%s*(.-)%s*$')
  if #candidate<32 or #candidate>128 or candidate:find('[^%w_-]')then status.Text='Paste your complete access key.';return end
  busy=true;open.Text='Checking…';status.Text='Connecting to AINZ…'
  local body,message=fetch('/files/AINZ-all-games.luau',candidate)
  if not cancelled and dialog.Parent then
   if body then key=candidate;bundle=body else status.Text=message;open.Text='Unlock AINZ' end
  end
  busy=false
 end
 open.Activated:Connect(submit)
 box.FocusLost:Connect(function(enter)if enter then submit()end end)
 cancel.Activated:Connect(function()cancelled=true end)
 while not key and not cancelled and dialog.Parent do task.wait(.1)end
 dialog:Destroy();dialog=nil
 assert(key,'AINZ loading cancelled.')
 return key,bundle
end
env.AINZOnlineLoaderBusy=true
local ok,result=xpcall(function()
 local key=(env.AINZKeyUserId==nil or env.AINZKeyUserId==robloxUserId)and env.AINZKey or nil
 if not key then
  local loaded,saved=pcall(function()return Http:JSONDecode(readfile(keyFile))end)
  if loaded and type(saved)=='table'and saved.userId==robloxUserId and saved.host==HOST
   and type(saved.key)=='string'and #saved.key>=32 and #saved.key<=128 and not saved.key:find('[^%w_-]')then key=saved.key end
 end
 local bundle
 if type(key)=='string' and #key>0 then
  local message,status;bundle,message,status=fetch('/files/AINZ-all-games.luau',key)
  if not bundle then
   if status==401 or status==403 or status==409 then
    env.AINZKey=nil;env.AINZKeyUserId=nil
    local removed=type(delfile)=='function'and pcall(delfile,keyFile)
    if not removed then pcall(writefile,keyFile,'{}')end
    warn(message);key=nil
   else error(message,0)end -- Keep remembered keys during outages or throttling.
  end
 end
 if not bundle then key,bundle=requestKey()end
 env.AINZKey=key;env.AINZKeyUserId=robloxUserId
 local remembered=pcall(writefile,keyFile,Http:JSONEncode({version=1,userId=robloxUserId,host=HOST,key=key}))
 if not remembered then warn('AINZ could not remember this key. You may need to enter it next time.')end
 local scripts={{'AINZ-all-games.luau',bundle}}
 for _,name in ipairs({"AINZ-launcher.luau","AINZ-flee-the-facility.luau","AINZ-run-a-sari-sari-store.luau"})do
  local body,message=fetch('/files/'..name,key);assert(body,message);scripts[#scripts+1]={name,body}
 end
 for _,entry in ipairs(scripts)do local fn,reason=loadstring(entry[2],'@'..entry[1]);assert(fn,reason)end
 local assets={}
 local logo,message=fetch('/files/ainz.png',key);assert(logo,message);assert(png(logo),'Invalid AINZ logo');assets[#assets+1]={'ainz.png',logo}
 local packed,packError=fetch('/files/ainz-icon-assets.json',key);assert(packed,packError)
 local decoded,pack=pcall(function()return Http:JSONDecode(packed)end)
 assert(decoded and type(pack)=='table' and pack.version==1 and type(pack.icons)=='table','Invalid AINZ icon bundle')
 local alphabet='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
 local lookup={};for i=1,#alphabet do lookup[alphabet:sub(i,i)]=i-1 end
 local function decode64(encoded)
  assert(type(encoded)=='string' and #encoded<=262144 and #encoded%4==0 and encoded:match('^[%w+/]*=?=?$'),'Invalid icon encoding')
  local out={}
  for i=1,#encoded,4 do
   local a,b,c,d=encoded:sub(i,i),encoded:sub(i+1,i+1),encoded:sub(i+2,i+2),encoded:sub(i+3,i+3)
   assert(lookup[a] and lookup[b] and (c=='=' or lookup[c]) and (d=='=' or lookup[d]),'Invalid icon encoding')
   assert((c~='=' or d=='=') and ((c~='=' and d~='=') or i+3==#encoded),'Invalid icon padding')
   local value=lookup[a]*262144+lookup[b]*4096+(lookup[c] or 0)*64+(lookup[d] or 0)
   out[#out+1]=string.char(math.floor(value/65536)%256)
   if c~='=' then out[#out+1]=string.char(math.floor(value/256)%256)end
   if d~='=' then out[#out+1]=string.char(value%256)end
  end
  return table.concat(out)
 end
 for _,name in ipairs({"ui-icons/add.png","ui-icons/animation-emotes.png","ui-icons/animation-failed.png","ui-icons/animation-favorite.png","ui-icons/animation-loop.png","ui-icons/animation-packs.png","ui-icons/animation-pause.png","ui-icons/animation-play.png","ui-icons/animation-random.png","ui-icons/animation-walk.png","ui-icons/animations.png","ui-icons/arrow-down.png","ui-icons/arrow-left.png","ui-icons/arrow-right.png","ui-icons/arrow-up.png","ui-icons/avatar.png","ui-icons/bell.png","ui-icons/blackhole.png","ui-icons/camera.png","ui-icons/check.png","ui-icons/chevron-down.png","ui-icons/chevron-left.png","ui-icons/chevron-right.png","ui-icons/chevron-up.png","ui-icons/clipboard.png","ui-icons/clock.png","ui-icons/close.png","ui-icons/code.png","ui-icons/copy.png","ui-icons/defense.png","ui-icons/diagnostics.png","ui-icons/dock.png","ui-icons/download.png","ui-icons/drag.png","ui-icons/edit.png","ui-icons/error.png","ui-icons/external-link.png","ui-icons/eye-off.png","ui-icons/eye.png","ui-icons/file.png","ui-icons/filter.png","ui-icons/folder.png","ui-icons/fps.png","ui-icons/fun.png","ui-icons/globe.png","ui-icons/heart.png","ui-icons/help.png","ui-icons/home.png","ui-icons/image.png","ui-icons/info.png","ui-icons/keybind.png","ui-icons/link.png","ui-icons/loading.png","ui-icons/lock.png","ui-icons/maximize.png","ui-icons/menu.png","ui-icons/minimize.png","ui-icons/moon.png","ui-icons/mouse.png","ui-icons/move-blocks.png","ui-icons/movement.png","ui-icons/nds.png","ui-icons/offense.png","ui-icons/overview.png","ui-icons/palette.png","ui-icons/pin.png","ui-icons/ping.png","ui-icons/players.png","ui-icons/refresh.png","ui-icons/remove.png","ui-icons/restore.png","ui-icons/save.png","ui-icons/search.png","ui-icons/servers.png","ui-icons/settings.png","ui-icons/sliders.png","ui-icons/sort.png","ui-icons/stop.png","ui-icons/success.png","ui-icons/sun.png","ui-icons/terminal.png","ui-icons/touch.png","ui-icons/trash.png","ui-icons/unlock.png","ui-icons/unpin.png","ui-icons/upload.png","ui-icons/utilities.png","ui-icons/volume-off.png","ui-icons/volume.png","ui-icons/warning.png","ui-icons/wifi.png"})do
  local body=decode64(pack.icons[name]);assert(png(body),'Invalid AINZ image: '..name);assets[#assets+1]={name,body}
 end
 if not isfolder('ui-icons')then makefolder('ui-icons')end
 for _,group in ipairs({assets,scripts})do for _,entry in ipairs(group)do writefile(entry[1],entry[2]);assert(readfile(entry[1])==entry[2],'Could not save '..entry[1])end end
 env.AINZIconAsset=nil
 return assert(loadstring(readfile('AINZ-launcher.luau'),'@AINZ-launcher.luau'))()
end,debug.traceback)
if dialog then dialog:Destroy()end
env.AINZOnlineLoaderBusy=nil
assert(ok,result)
return result
