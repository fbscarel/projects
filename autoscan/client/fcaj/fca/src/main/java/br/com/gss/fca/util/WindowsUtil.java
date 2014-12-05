package br.com.gss.fca.util;

import java.io.File;
import java.util.ArrayList;
import java.util.List;

import br.com.gss.fca.Messages;
import br.com.gss.fca.exception.FCAException;

import com.sun.jna.Platform;
import com.sun.jna.platform.win32.Advapi32;
import com.sun.jna.platform.win32.Advapi32Util;
import com.sun.jna.platform.win32.WinDef;
import com.sun.jna.platform.win32.Advapi32Util.Account;
import com.sun.jna.platform.win32.Kernel32;
import com.sun.jna.platform.win32.Tlhelp32;
import com.sun.jna.platform.win32.Tlhelp32.PROCESSENTRY32;
import com.sun.jna.platform.win32.WinNT.HANDLE;
import com.sun.jna.platform.win32.WinNT.PSIDByReference;
import com.sun.jna.platform.win32.WinNT.WELL_KNOWN_SID_TYPE;
import com.sun.jna.platform.win32.WinReg;
import com.sun.jna.platform.win32.WinReg.HKEY;

public class WindowsUtil {

	private static final String SHELL_KEYS = "Software\\Microsoft\\Windows\\CurrentVersion\\Explorer\\Shell Folders";
	private static final String LOCAL_APP_DATA = "Local AppData";
	private static final String ROAMING_APP_DATA = "AppData";
	private static final String DESKTOP = "Desktop";
	
	private static String localAppDataDirectory = null;
	private static String roamingAppDataDirectory = null;
	private static String desktopDirectory = null;

	public static final String FILE_SEPARATOR = System.getProperty("file.separator");
	
	static{
		localAppDataDirectory = Advapi32Util.registryGetStringValue(WinReg.HKEY_CURRENT_USER, SHELL_KEYS, LOCAL_APP_DATA);
		roamingAppDataDirectory =  Advapi32Util.registryGetStringValue(WinReg.HKEY_CURRENT_USER, SHELL_KEYS, ROAMING_APP_DATA);
		desktopDirectory =  Advapi32Util.registryGetStringValue(WinReg.HKEY_CURRENT_USER, SHELL_KEYS, DESKTOP);
	}
		
	public static boolean isUserWindowsAdmin() {
		Account[] groups = Advapi32Util.getCurrentUserGroups();
		for(Account group:groups) {
			PSIDByReference sid = new PSIDByReference();
			Advapi32.INSTANCE.ConvertStringSidToSid(group.sidString, sid);
			if(Advapi32.INSTANCE.IsWellKnownSid(sid.getValue(), WELL_KNOWN_SID_TYPE.WinBuiltinAdministratorsSid))
				return true;
		}
		
		return false;
	}
	
	public static boolean is64Bit() {
		return Platform.is64Bit();
	}
	
	public static final boolean isProcessRunning(String processname) {
		List<String> processList = getRunningProcess();
		for(String process : processList){
			if(process.toLowerCase().contains(processname.toLowerCase()))
				return true;
		}
		
		return false;
	}
	
	private static List<String> getRunningProcess(){
		List<String> processList = new ArrayList<String>();
		
		HANDLE handle = Kernel32.INSTANCE.CreateToolhelp32Snapshot(Tlhelp32.TH32CS_SNAPPROCESS, new WinDef.DWORD(0));
		PROCESSENTRY32 entry = new PROCESSENTRY32();
		boolean success = Kernel32.INSTANCE.Process32First(handle, entry);
		while(success) {
			processList.add(new String(entry.szExeFile));
			success = Kernel32.INSTANCE.Process32Next(handle, entry);
		}
		
		Kernel32.INSTANCE.CloseHandle(handle);
		return processList;
	}
	
	public static final boolean addRegistry(HKEY root, String parent, String key){
		createRegistryPath(root, parent);
    	return Advapi32Util.registryCreateKey(root, parent, key);
    }
	
    public static final boolean addRegistryToLocalMachine(String parent, String key){
    	return addRegistry(WinReg.HKEY_LOCAL_MACHINE, parent, key);
    }
    
    private static final void createRegistryPath(HKEY root, String path) {
    	String[] pathItems = path.split("\\\\");
    	String parent = "";
    	
    	for(String pathItem : pathItems) {
    		String key = pathItem;
    		if(!Advapi32Util.registryKeyExists(root, key))
    			Advapi32Util.registryCreateKey(root, parent, key);
    		parent = parent.length() == 0 ? key : parent + "\\" + key;
    	}
    }
    
	public static void removeRegistry(HKEY root, String keyPath, String keyName) {
		Advapi32Util.registryDeleteKey(root, keyPath, keyName);
	}
	
	public static void removeRegistryFromLocalMachine(String keyPath, String keyName) {
		removeRegistry(WinReg.HKEY_LOCAL_MACHINE, keyPath, keyName);
	}
		
	public static String getHostsPath() throws FCAException{
		return FileUtil.combine(true, System.getenv("SystemRoot"), "system32", "drivers","etc", "hosts");
	}
	
	public static String getSystemDirectory() throws FCAException {
		String path = null;
		if(is64Bit()){
			path = System.getenv("SystemRoot") + FILE_SEPARATOR + "SysWOW64";
			if(new File(path).exists()){
				return path;
			}
			throw new FCAException(Messages.getString("error.system.folder.not.found"));
		}else{
			path = System.getenv("SystemRoot") + FILE_SEPARATOR + "System32";
			if(new File(path).exists()){
				return path;
			}
			
			path = System.getenv("SystemRoot") + FILE_SEPARATOR + "system32";
			if(new File(path).exists()){
				return path;
			}
			
			path = System.getenv("SystemRoot") + FILE_SEPARATOR + "system";
			if(new File(path).exists()){
				return path;
			}
			throw new FCAException(Messages.getString("error.system.folder.not.found"));
		}
	}


	public static String getLocalApplicationData() {
		return localAppDataDirectory;
	}

	public static String getRoamingApplicationData() {
		return roamingAppDataDirectory;
	}

	public static String getDesktopPath() {
		return desktopDirectory;
	}


}
