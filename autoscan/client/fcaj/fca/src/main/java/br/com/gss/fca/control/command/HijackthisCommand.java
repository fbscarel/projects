package br.com.gss.fca.control.command;

import java.io.BufferedReader;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.IOException;
import java.io.InputStreamReader;
import java.nio.charset.Charset;
import java.util.ArrayList;
import java.util.List;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import br.com.gss.fca.Messages;
import br.com.gss.fca.exception.FCAException;
import br.com.gss.fca.gui.FeedbackDelegate;
import br.com.gss.fca.model.Configuration;
import br.com.gss.fca.util.FileUtil;
import br.com.gss.fca.util.WindowsUtil;

public class HijackthisCommand extends ExecuteCommand{

	
	private List<String> whitelistPrograms;
	
	public HijackthisCommand(FeedbackDelegate feebackWindow) {
		super(feebackWindow, getParameters());
	}

	private static String[] getParameters() {
		String [] parameters = new String[]{Configuration.getInstance().getHijackthisFile(), "/silentautolog"}; 
		return parameters;
	}

	
	@Override
	public void executeCommand() throws FCAException{
		if(isAdministrator()){
			generateHijackThisKeys();
			super.executeCommand();
			this.readWhitelist();
			this.copyO4Files(this.parserHijackOutput());
			this.copyOutputLog();
			removeHijackThisKeys();
		}else{
			this.feebackWindow.onFeedback(Messages.getString("message.administrator.required"));
		}
	}
	


	private void copyO4Files(List<String> files){
		if (files != null) {
            for (String file : files) {
                String filePath = file;

                //removes parameters with "/"
                if (filePath.contains("/")) {
                    filePath = file.substring(0, file.indexOf("/") - 1);
                }

                //4 from ".exe" and -1 because of it is length not index
                int indexOf = filePath.toLowerCase().lastIndexOf(".exe");
                if (indexOf > 0 && (indexOf != (filePath.length() - 4))) {
                    filePath = file.substring(0, indexOf + 4);
                } else {
            		if(!new File(filePath).exists()){
            			try{
		                    //tests if it is a dll or an executable in system path
		                    if(new File(FileUtil.combine(WindowsUtil.getSystemDirectory(),filePath + ".dll")).exists()){
		                        filePath = FileUtil.combine(WindowsUtil.getSystemDirectory(),filePath + ".dll");
		                    }
		                    if(new File(FileUtil.combine(WindowsUtil.getSystemDirectory(),filePath + ".exe")).exists()){
		                    	 filePath = FileUtil.combine(WindowsUtil.getSystemDirectory(),filePath + ".exe");
		                    }
            			}catch(FCAException fcaExc){
            				fcaExc.printStackTrace();
            			}
            		}
                }
                if (new File(filePath).exists()) {
                    this.copyIfNotInWhitelist(filePath);
                }
            }
        }
	}
	
	
	private void copyOutputLog() {
		try {
			Configuration c = Configuration.getInstance();
			File fileOutput = new File(c.getHijackthisOutputFile());
			FileUtil.copyFile(fileOutput.getAbsolutePath(), c.getHijackthisOutputPath());
		} catch (FCAException e) {
			e.printStackTrace();
		}
	}
	
    private void copyIfNotInWhitelist(String filePath) {
    	String name = new File(filePath).getName();
    	if(!this.whitelistPrograms.contains(name)){
    		try {
				FileUtil.copyFile(filePath, Configuration.getInstance().getHijackthisOutputPath());
			} catch (FCAException e) {
				e.printStackTrace();
			}
    	}
    }

	private void readWhitelist() {
		 this.whitelistPrograms = FileUtil.readLines(Configuration.getInstance().getHijackthisWhitelist());		
	}

	private List<String> parserHijackOutput() {
		
		List<String> lines = new ArrayList<String>();
		File f = new File(Configuration.getInstance().getHijackthisOutputFile());
		if(!f.exists()){
			feebackWindow.onError("Arquivo de saída do hijack não encontrado ", null);
			return lines;
		}
		
		FileInputStream fis = null;
		BufferedReader br = null;
		try {
			fis = new FileInputStream(f);
			br = new BufferedReader(new InputStreamReader(fis, Charset.forName("UTF-8")));
			String line = null;
			Pattern p = Pattern.compile("O4\\s\\-\\s.*\\:\\s\\[(.*)\\]\\s(.*)");
			while ((line = br.readLine()) != null) {
				if (line.startsWith("O4 - ")) {
					Matcher m = p.matcher(line);
					if(m.matches()){
                        String pathFile = "";
                        String pathMatch = m.group(2);
                        if (pathMatch.startsWith("\"")) {
                            pathFile = pathMatch.substring(1, pathMatch.indexOf("\"", 2));
                        } else {
                            pathFile = pathMatch;
                        }
						lines.add(pathFile);
					} else {
						if (line.contains(" = ")) {
							line = (line.split(" = "))[1];
							lines.add(line);
						}
					}
				}
			}
		} catch (FileNotFoundException e) {
			e.printStackTrace();
		} catch (IOException e) {
			e.printStackTrace();
		}finally{
			try {
				br.close();
			} catch (IOException e) {
				e.printStackTrace();
			}
			br = null;
			fis = null;
		}
		return lines;
	}

	private void generateHijackThisKeys() {
         try {
             String parent = WindowsUtil.is64Bit() ? "SOFTWARE\\Wow6432Node\\TrendMicro" : "SOFTWARE\\TrendMicro";
             String key = "HijackThis";
             WindowsUtil.addRegistryToLocalMachine(parent, key);
         } catch (Exception e ){ 
        	 feebackWindow.onError(e.getMessage(), e);
         }
     }

	 private void removeHijackThisKeys() {
         try {
        	 String keyPath = WindowsUtil.is64Bit() ? "SOFTWARE\\Wow6432Node\\TrendMicro" : "SOFTWARE\\TrendMicro";
             String keyName = "HijackThis";
             WindowsUtil.removeRegistryFromLocalMachine(keyPath, keyName);
         } catch (Exception e ){ 
        	 feebackWindow.onError(e.getMessage(), e);
         }
     }
	
	@Override
	public String getCommandName() {
		return Messages.getString("command.hijackthis");
	}

	private boolean isAdministrator() {
		return WindowsUtil.isUserWindowsAdmin();
	}

}
