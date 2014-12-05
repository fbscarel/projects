package br.com.gss.fca.model;

import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.text.ParseException;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.Properties;

/**
 * Class object keeps constants and paths that are used by commands.
 * 
 * It is a Singleton Desing pattern.
 * @author Paula.Fernandes
 */
public class Configuration {

	private static final String PROPERTY_FILE = "fca.conf";

	private static Configuration instance;
	
	private final String hijackthisFile;
	private final String hijackthisOutputFile;
	private final String hijackthisWhitelistFile;
	private final String hijackthisOutputPath;
	private final String hostsOutputPath;
	private final String outPath;
	private final String pscpFile;
	private final String browserPath;
	
	private Properties prop;
	private String username;
	private String hostname;
	private String tempOutFile;
	private Date incidentDate;
	
	private Configuration() {
		
		this.hijackthisOutputPath = "out\\hijack\\";
		this.hijackthisFile = "resources\\HijackThis.exe";
		this.hijackthisOutputFile = "resources\\hijackthis.log";
		this.hijackthisWhitelistFile = "resources\\hijackthisWhitelist.txt";
		
		this.hostsOutputPath = "out\\hosts\\";
		this.browserPath = "out\\browsers";
		
		this.pscpFile = "cli\\pscp.bat";

		this.outPath = "out";
	}
	
	public static Configuration getInstance(){
		if(instance==null){
			instance = new Configuration();
			instance.loadConfig();
		}
		return instance;
	}
	
	private void loadConfig() {
		this.prop = new Properties();
        try {
        	InputStream inputStream = null;
        	if(!(new File(PROPERTY_FILE).exists())){
        		inputStream = getClass().getClassLoader().getResourceAsStream(PROPERTY_FILE);
        	}else{
        		inputStream = new FileInputStream(new File(PROPERTY_FILE));
        	}
        	if(inputStream!=null){
        		prop.load(inputStream);
        		SimpleDateFormat dateFormat = new SimpleDateFormat("yyyy-MM-dd");
        		username = prop.getProperty("USER");
        		hostname = prop.getProperty("CNAME");
        		incidentDate = dateFormat.parse(prop.getProperty("INCIDENT_DATE"));
        	}
		} catch (IOException e) {
			e.printStackTrace();
		} catch (ParseException e) {			
			e.printStackTrace();
		}
        if(username==null || username.equals("")){
        	this.username = "Default";
        }
        if(hostname==null|| hostname.equals("")){
        	this.hostname = "Host";
        }
        if(incidentDate == null){
        	incidentDate = new Date();
        }
		
	}
	
	/**
	 * @return Path to hijackthis.exe file <br>
	 * Default: ~fca.exe\resources\hijackthis.exe
	 */
	public String getHijackthisFile() {
		return this.hijackthisFile;
	}

	/**
	 * @return Name of the hijackthis output file (hijackthis.log) <br>
	 * Default: fca.exe\resources\hijackthis.log
	 */
	public String getHijackthisOutputFile() {
		return this.hijackthisOutputFile;
	}

	/**
	 * @return Path to copy the hijackthis evidences. <br>
	 * Default: fca.exe\out\hijack\
	 */
	public String getHijackthisOutputPath() {
		return this.hijackthisOutputPath;
	}

	/**
	 * @return Path to hijackthis whitelist entries. <br>
	 * Default: fca.exe\resources\hijackthisWhitelist.txt
	 */
	public String getHijackthisWhitelist() {
		return hijackthisWhitelistFile;
	}
	
	/**
	 * @return Path to copy hosts file <br>
	 * Default: fca.exe\out\hosts\hosts
	 */
	public String getHostsOutputPath() {
		return hostsOutputPath;
	}

	/**
	 * @return Path to zip. <br>
	 * Default: fca.exe\out\
	 */
	public String getOutPath() {
		return outPath;
	}

	/**
	 * @return Username in the fca.conf fine. <br>
	 * Default: Default
	 */
	public String getUsername() {
		return username;
	}
	
	/**
	 * @return Hostname in the fca.conf fine. <br>
	 * Default: Default
	 */
	public String getHostname() {
		return hostname;
	}

	public String getPscpFile() {
		return pscpFile;
	}

	/**
	 * @return Path to 7za.exe. <br>
	 * Name: USERNAME_HOSTNAME_TIMESTAMP.7z
	 */
	public String getTempOutFile() {
		return tempOutFile;
	}

	/**
	 * Method to store output file location and name
	 * @param tempOutFile
	 */
	public void setTempOutFile(String tempOutFile) {
		this.tempOutFile = tempOutFile;
	}
	
	/**
	 * Method to store the brouwser path output
	 * @return brower path output
	 */
	public String getBrowserPath() {
		return browserPath;
	}
	
	public Date getIncidentDate() {
		return incidentDate;
	}
}
