package br.com.gss.fca.control.command;

import java.io.File;
import java.io.IOException;
import java.util.Date;

import br.com.gss.fca.Messages;
import br.com.gss.fca.exception.FCAException;
import br.com.gss.fca.gui.FeedbackDelegate;
import br.com.gss.fca.model.Configuration;
import br.com.gss.fca.util.ZipUtil;

public class PackCommand extends AbstractCommand {	
	public PackCommand(FeedbackDelegate feebackWindow) {
		super(feebackWindow);
	}
	
	@Override
	public String getCommandName() {
		return Messages.getString("command.pack");
	}

	@Override
	protected void executeCommand() throws FCAException {
		try {
			Configuration c = Configuration.getInstance();
			String fileName = String.format("%s_%s_%d.zip", c.getUsername().trim(), c.getHostname().trim(), new Date().getTime());
			fileName = fileName.toLowerCase();
			
			String pathToZip = new File(c.getOutPath()).getCanonicalPath();
			ZipUtil.createZip(pathToZip, fileName);
			Configuration.getInstance().setTempOutFile(fileName);
		} catch (IOException e) {
			throw new FCAException(Messages.getString("error.zip.file.create"), e);
		}
	}
}
