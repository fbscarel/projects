package br.com.gss.fca.util;

import java.io.BufferedReader;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.FilenameFilter;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.OutputStream;
import java.nio.charset.Charset;
import java.util.ArrayList;
import java.util.List;

import br.com.gss.fca.Messages;
import br.com.gss.fca.exception.FCAException;

public class FileUtil {
	
	public static String getParentName(File file) {
	    if(file == null || file.isDirectory()) {
	            return null;
	    }
	    String parent = file.getParent();
	    parent = parent.substring(parent.lastIndexOf(WindowsUtil.FILE_SEPARATOR) + 1, parent.length());
	    return parent;      
	}

	/**
	 * Reads file from file using UTF-8 encoding.
	 * @param filePath
	 * @return
	 */
	public static List<String> readLines(String filePath) {
		FileInputStream fis = null;
		BufferedReader br = null;
		List<String> lines = new ArrayList<String>();
		try {
			fis = new FileInputStream(filePath);
			br = new BufferedReader(new InputStreamReader(fis, Charset.forName("UTF-8")));
			String line;
			while ((line = br.readLine()) != null) {
				lines.add(line);
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

	/**
	 * Method validate if file exists and directory exists before copy. If directory does not exist, it creates. If file to copy does not exists, throws an Exception.
	 * @param filePath - Path of file that you want to copy
	 * @param directoryPath - Destiny directory 
	 * @throws FCAException
	 */
	public static void copyFile(String filePath, String directoryPath) throws FCAException {
		File directory = new File(directoryPath);
		if(!directory.exists()){
			if(!directory.mkdirs()){
				throw new FCAException(Messages.getString("error.folder.not.created", directory.getAbsolutePath()));
			}
		}
		File file = new File(filePath);
		if(!file.exists()){
			throw new FCAException(Messages.getString("error.file.not.found", filePath));
		}
		try {
			copyFileUsingFileStreams(file, new File(directoryPath + WindowsUtil.FILE_SEPARATOR + file.getName()));
		} catch (IOException e) {
			throw new FCAException(Messages.getString("error.file.not.found", filePath));
		}
	}

	
	private static void copyFileUsingFileStreams(File source, File dest) throws IOException {
		InputStream input = null;
		OutputStream output = null;
		try {
			if(!dest.exists()){
				dest.createNewFile();
			}
			input = new FileInputStream(source);
			output = new FileOutputStream(dest);
			byte[] buf = new byte[1024];
			int bytesRead;
			while ((bytesRead = input.read(buf)) > 0) {
				output.write(buf, 0, bytesRead);
			}
		} catch (Exception e){ 
			e.printStackTrace();
		}finally {
			input.close();
			output.close();
		}
	}

	public static String[] getDirectories(String profileFolder) {
		File file = new File(profileFolder);
		String[] directories = file.list(new FilenameFilter() {
		  public boolean accept(File current, String name) {
		    return new File(current, name).isDirectory();
		  }
		});
		return directories;
	}

	public static void createDirectory(String directoryPath) throws FCAException {
		File directory = new File(directoryPath);
		if(!directory.exists()){
			if(!directory.mkdirs()){
				throw new FCAException(Messages.getString("error.folder.not.created", directory.getAbsolutePath()));
			}
		}		
	}
	
	public static String combine(String directoryPath, String fileName) {
		if(directoryPath.endsWith(WindowsUtil.FILE_SEPARATOR)){
			return directoryPath + fileName;
		}
		return directoryPath + WindowsUtil.FILE_SEPARATOR + fileName;
	}

	public static String combine(boolean isFile, String ... paths) throws FCAException {
		StringBuilder sb = new StringBuilder();
		int i = 0;
		for (i = 0; i < ( paths.length -1 ); i++) {
			if(paths[i]==null){
				throw new FCAException(Messages.getString("error.folder.not.found", paths.toString()));
			}
			sb.append(paths[i] + WindowsUtil.FILE_SEPARATOR);
		}
		sb.append(paths[i]);
		if(!isFile){
			sb.append(WindowsUtil.FILE_SEPARATOR);
		}
		return sb.toString();
	}

}
