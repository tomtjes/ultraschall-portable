dofile(reaper.GetResourcePath().."/UserPlugins/ultraschall_api.lua")

retval, URL = reaper.GetUserInputs("Add Ultraschall Update-URL", 1, "URL(.xml): ", "")
URL=string.gsub(URL, "/blob/", "/raw/")
if retval==false then reaper.MB("No URL given", "Aborted", 0) return end


--URL="file:///C:/temp/index-test.xml"
if URL:match(".xml")==nil then reaper.MB("No index-file given", "Aborted", 0) return end
Name=URL:match(".*/(.-)/")

--if ol==nil then return end

majorversion, subversion, bits, operating_system, portable, betaversion = ultraschall.GetReaperAppVersion()

target_dir="c:\\temp\\uploads"

--if ll==nil then return end

retval, target_dir = reaper.JS_Dialog_BrowseForFolder("Select target folder. A new folder called Ultraschall_portable will be created there.", reaper.GetExePath())
D=target_dir.."/"..Name.."/reaper.exe"

--if ll==nil then return end

if retval==1 then target_dir=target_dir.."/"..Name
else
return
end

found_dirs, dirs_array, found_files, files_array = ultraschall.GetAllRecursiveFilesAndSubdirectories(reaper.GetResourcePath())
found_dirs2, dirs_array2, found_files2, files_array2 = ultraschall.GetAllRecursiveFilesAndSubdirectories(reaper.GetExePath())

-- Resource-folder first

A=reaper.RecursiveCreateDirectory(target_dir, 0)
if A==0 then print2("Folder already exists") return 
end


-- create folder structure - Resourcefolder
for i=1, found_dirs do
  temp1=string.gsub(reaper.GetResourcePath(), "\\", "/")
  temp2=string.gsub(dirs_array[i], "\\", "/")
  temp3=target_dir..temp2:sub(temp1:len()+1,-1)
  reaper.RecursiveCreateDirectory(temp3, 0)
end

-- create folder structure - Exefolder, if not portable installation already
if portable==false then
  for i=1, found_dirs2 do
    temp1=string.gsub(reaper.GetExePath(), "\\", "/")
    temp2=string.gsub(dirs_array2[i], "\\", "/")
    temp3=target_dir..temp2:sub(temp1:len()+1,-1)
    reaper.RecursiveCreateDirectory(temp3, 0)
  end
end


function copy_files2()
  o=i
  -- copy files from the exefolder, if not already copy due being a portable installation
  if portable==false then
    for a=1, 150 do
      retval = ultraschall.PrintProgressBar(true, 50, found_files2, i, true, 5, "Copying Exefolder:", 
                                          "File: "..
                                          target_dir..temp3..
                                          "\n -> \n"..
                                          files_array2[i])
      temp1=string.gsub(reaper.GetExePath(), "\\", "/")
      temp2=string.gsub(files_array2[i], "\\", "/")
      temp3=temp2:sub(temp1:len()+1,-1)
      
      retval = ultraschall.MakeCopyOfFile_Binary(files_array2[i], target_dir..temp3)
      i=i+1
      if i>found_files2 then break end
    end
      if i<=found_files2 then reaper.defer(copy_files2) else ultraschall.CloseReaScriptConsole() end
  else
    reaper.RecursiveCreateDirectory(target_dir.."/Scripts/UltraschallInstaller/", 0)
    reaper.RecursiveCreateDirectory(target_dir.."/Scripts/UltraschallInstaller/Web_Installer", 0)
    ultraschall.WriteValueToFile(target_dir.."/Scripts/UltraschallInstaller/Web_Installer/ultraschall_update_script.lua", [[
    A,B=reaper.get_action_context()
    URL="]]..URL..[["
    reaper.AddRemoveReaScript(false, 0, B, true)
    os.remove(B)
    
    retval, error_msg = reaper.ReaPack_AddSetRepository("UltraschallInstaller", URL, true, 1)
    integer = reaper.NamedCommandLookup("_REAPACK_SYNC")
    reaper.Main_OnCommand(integer, 0)
    
    --reaper.MB("For continuing installation, restart Reaper, please",  "Step 2: Download completed", 0)
    function main()
        A=reaper.JS_Window_Find("ReaPack Notice", true)
        if A~=nil then 
            reaper.JS_Window_Destroy(A)
            reaper.JS_Window_Destroy(reaper.JS_Window_Find("Transaction report", true))
            B=reaper.AddRemoveReaScript(true, 0, reaper.GetResourcePath().."/UserPlugins/Ultraschall-WebInstaller/Scripts/ultraschall_install_update.lua", true)
            reaper.Main_OnCommand(B,0)
            endit=true
        end
        
        if endit~=true then reaper.defer(main) else 
            --reaper.MB("For continuing installation, restart Reaper, please",  "Step 2: Download completed", 0) 
        end
    end
    
    
    main()
    
    
    ]])
    ultraschall.CloseReaScriptConsole()
    target_dir=string.gsub(target_dir, "\\", ultraschall.Separator)
    target_dir=string.gsub(target_dir, "/", ultraschall.Separator)
    --reaper.CF_LocateInExplorer(target_dir..ultraschall.Separator)
    --reaper.MB("Quit Reaper now, go into the target-folder and start Reaper.exe/Reaper64.app", "Step1: Portable Installation Completed", 0)
    --reaper.ExecProcess(target_dir.."/reaper.exe", -1)
    A,B,C=reaper.ExecProcess(D, -1)
    reaper.Main_OnCommand(40004,0)
  end
end

function copy_files()
  -- copy files from the resourcefolder
  for a=1, 150 do
    retval = ultraschall.PrintProgressBar(true, 50, found_files, i, true, 5, "Copying Resourcefolder:", "File: "..target_dir..temp3.."\n -> \n"..files_array[i])
    temp1=string.gsub(reaper.GetResourcePath(), "\\", "/")
    temp2=string.gsub(files_array[i], "\\", "/")
    temp3=temp2:sub(temp1:len()+1,-1)
    
    retval = ultraschall.MakeCopyOfFile_Binary(files_array[i], target_dir..temp3)
    i=i+1
    if i>found_files then break end
  end
    if i<=found_files then 
      reaper.defer(copy_files)
    else
      i=1
      temp3=""
      copy_files2()
    end
end

i=1
copy_files()

