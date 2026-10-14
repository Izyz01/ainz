-- Public entry point. GitHub credentials stay on the release host.
local HOST='https://ainz-release-host.dfcis-suggestion-box.workers.dev'
local env=getgenv()
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
 local ok,response=pcall(send,{Url=HOST..path,Method='GET',Headers=key and {Authorization='Bearer '..key} or {}})
 if not ok or type(response)~='table' then return nil,'Cannot connect to AINZ. Try again.' end
 local status=tonumber(response.StatusCode or response.Status)
 if status==401 then return nil,'Invalid or revoked key.' end
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
 label('Enter the access key you received',140,24)
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
 local key=env.AINZKey
 local bundle
 if type(key)=='string' and #key>0 then
  local message;bundle,message=fetch('/files/AINZ-all-games.luau',key)
  if not bundle then env.AINZKey=nil;warn(message);key=nil end
 end
 if not bundle then key,bundle=requestKey()end
 local scripts={{'AINZ-all-games.luau',bundle}}
 for _,name in ipairs({'AINZ-launcher.luau','AINZ-flee-the-facility.luau'})do
  local body,message=fetch('/files/'..name,key);assert(body,message);scripts[#scripts+1]={name,body}
 end
 for _,entry in ipairs(scripts)do local fn,reason=loadstring(entry[2],'@'..entry[1]);assert(fn,reason)end
 local assets={}
 for _,name in ipairs({'ainz.png','ui-icons/close.png','ui-icons/diagnostics.png','ui-icons/fps.png','ui-icons/info.png','ui-icons/minimize.png','ui-icons/pin.png','ui-icons/ping.png','ui-icons/players.png','ui-icons/servers.png','ui-icons/settings.png','ui-icons/unpin.png'})do
  local body,message=fetch('/files/'..name,key);assert(body,message);assert(png(body),'Invalid AINZ image: '..name);assets[#assets+1]={name,body}
 end
 if not isfolder('ui-icons')then makefolder('ui-icons')end
 for _,group in ipairs({assets,scripts})do for _,entry in ipairs(group)do writefile(entry[1],entry[2]);assert(readfile(entry[1])==entry[2],'Could not save '..entry[1])end end
 env.AINZIconAsset=nil;env.AINZKey=key -- Session memory only; never save the access key to disk.
 return assert(loadstring(readfile('AINZ-launcher.luau'),'@AINZ-launcher.luau'))()
end,debug.traceback)
if dialog then dialog:Destroy()end
env.AINZOnlineLoaderBusy=nil
assert(ok,result)
return result
