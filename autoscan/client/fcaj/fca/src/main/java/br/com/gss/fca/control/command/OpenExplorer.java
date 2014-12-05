package br.com.gss.fca.control.command;

import java.io.File;

import br.com.gss.fca.Messages;
import br.com.gss.fca.exception.FCAException;
import br.com.gss.fca.gui.FeedbackDelegate;
import br.com.gss.fca.gui.FeedbackDelegate.RETURN_CONFIRMATION;
import br.com.gss.fca.model.Configuration;
import br.com.gss.fca.util.FileUtil;
import br.com.gss.fca.util.WindowsUtil;

public class OpenExplorer extends AbstractCommand {

	public OpenExplorer(FeedbackDelegate feebackWindow) {
		super(feebackWindow);
	}

	@Override
	protected void executeCommand() throws FCAException {
		
		String filePath = Configuration.getInstance().getTempOutFile();
		String fileName = new File(filePath).getName();
		String desktopPath = WindowsUtil.getDesktopPath();
		
		FileUtil.copyFile(filePath, desktopPath);
		
		RETURN_CONFIRMATION r = this.feebackWindow.showConfirmationDialog(Messages.getString("message.open.explorer", fileName));
		if(r == RETURN_CONFIRMATION.OK){
			ExecuteCommand command = new ExecuteCommand(feebackWindow, new String[]{"explorer.exe", "\"" + desktopPath +"\""});
			command.execute();
		}
	}

	@Override
	public String getCommandName() {
		return null;
	}

}
