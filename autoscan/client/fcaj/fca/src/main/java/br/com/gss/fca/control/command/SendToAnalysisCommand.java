package br.com.gss.fca.control.command;

import java.io.File;

import br.com.gss.fca.Messages;
import br.com.gss.fca.exception.FCAException;
import br.com.gss.fca.gui.FeedbackDelegate;
import br.com.gss.fca.model.Configuration;
import br.com.gss.fca.util.WindowsUtil;

public class SendToAnalysisCommand extends ExecuteCommand {

	
	public SendToAnalysisCommand(FeedbackDelegate feebackWindow) {
		super(feebackWindow, getParameters());
	}
	
	private static String[] getParameters() {
		
		Configuration c = Configuration.getInstance();
		
		//String upperFolder = new File(new File(c.getPscpFile()).getAbsoluteFile().getParent()).getAbsoluteFile().getParent();
		//upperFolder = new File(upperFolder).getAbsoluteFile().getParent();
		String pscpFile 		= ".." + WindowsUtil.FILE_SEPARATOR  +c.getPscpFile();
		String[] parametersPack = new String[]{
			pscpFile,
			c.getTempOutFile()
		};
		return parametersPack;
	}
	
	@Override
	public String getCommandName() {
		return Messages.getString("command.send.pack");
	}
	
	protected void validateParameters() throws FCAException {
		if(!new File(parameters[0]).exists()){
			throw new FCAException(Messages.getString("error.pcscp.file.not.found", new File(parameters[0]).getAbsolutePath()));
		}
		if(!new File(parameters[1]).exists()){
			throw new FCAException(Messages.getString("error.zip.file.not.found"));
		}
	}

}
