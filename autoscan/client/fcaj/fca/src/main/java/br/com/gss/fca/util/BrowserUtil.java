package br.com.gss.fca.util;

import java.io.File;
import java.util.ArrayList;
import java.util.List;

public class BrowserUtil {
	
	public static boolean isGoogleChromeRunning(){
		return WindowsUtil.isProcessRunning("chrome");
	}
	
	public static boolean isMozillaFirefoxRunning(){
		return WindowsUtil.isProcessRunning("firefox");
	}
	
	public static boolean isInternetExplorerRunning(){
		return WindowsUtil.isProcessRunning("iexplore");
	}
	
	public static File getGoogleChromeDataFile(){
		List<String> profiles = getChromeProfiles();
        if (profiles != null) {
            for (String profileFolder : profiles) {
            	File dataFile = new File(profileFolder, "History");
                if (dataFile.exists()) {
                	return dataFile;
                }
            }
        }
        
		return null;
	}
	
	public static File getMozillaFirefoxDataFile(){
		List<String> profiles = getFirefoxProfiles();
        if (profiles != null) {
            for (String profileFolder : profiles) {
            	File dataFile = new File(profileFolder, "places.sqlite");
                if (dataFile.exists()) {
                    return dataFile;
                }
            }
        }
        
		return null;
	}
	
	private static List<String> getChromeProfiles() {
		List<String> profileFolders = getChromeBrowserProfileDirectories();

		List<String> profiles = new ArrayList<String>();
        if (profileFolders != null) {
        	for (String profileFolder: profileFolders){
	        	String[] subDirectories = FileUtil.getDirectories(profileFolder);
	            if (subDirectories != null) {
	                for (String subDirectory : subDirectories) {
	                    if (subDirectory.contains("Default") || subDirectory.contains("Profile")) {
	                        profiles.add(FileUtil.combine(profileFolder, subDirectory));
	                    }
	                }
	            }
        	}
        }
        return profiles;
	}
	
	private static List<String> getFirefoxProfiles() {
		List<String> profileFolders = getFirefoxBrowserProfileDirectories();
		List<String> profiles = new ArrayList<String>();
        if (profileFolders != null) {
        	for (String profileFolder: profileFolders){
        		String[] subDirectories = FileUtil.getDirectories(profileFolder);
        		if(subDirectories!=null){
	        		for (int i = 0; i < subDirectories.length; i++) {
	        			profiles.add(FileUtil.combine(profileFolder, subDirectories[i]));
					}
        		}
        	}
        }
        return profiles;
	}
	
	private static List<String> getFirefoxBrowserProfileDirectories() {
		List<String> profiles = new ArrayList<String>();
		if(WindowsUtil.getRoamingApplicationData()==null){
			System.out.println("Diretório roaming é nulo");
		}
		
        profiles.add(FileUtil.combine(WindowsUtil.getRoamingApplicationData(), "Mozilla\\Firefox\\Profiles"));
        return profiles;
    }
	
	private static List<String> getChromeBrowserProfileDirectories() {
        String[] chromeFolders = { "Chrome", "chromium", "Chrome SxS" };
        final String localApp = WindowsUtil.getLocalApplicationData();
        List<String> defaultFolders = new ArrayList<String>();
        for (String chromeFolder : chromeFolders) {
            String defaultFolder = 
            		localApp + WindowsUtil.FILE_SEPARATOR + 
            		"Google" + WindowsUtil.FILE_SEPARATOR + 
            		chromeFolder + WindowsUtil.FILE_SEPARATOR + 
            		"User Data" + WindowsUtil.FILE_SEPARATOR ;            
            File directory = new File(defaultFolder);
            if (directory.exists() && directory.isDirectory()) {
            	defaultFolders.add(defaultFolder);
            }
        }
        return defaultFolders;
    }

}
