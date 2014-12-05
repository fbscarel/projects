package br.com.gss.fca.control.command.browsers;

import br.com.gss.fca.Messages;
import br.com.gss.fca.exception.FCAException;
import br.com.gss.fca.gui.FeedbackDelegate;
import br.com.gss.fca.history.InternetExplorerHistoryManager;
import br.com.gss.fca.util.BrowserUtil;

public class IeAnalysisCommand extends BrowserAnalysisCommand {

	public IeAnalysisCommand(FeedbackDelegate feebackWindow) {
		super(feebackWindow);
	}

	@Override
	protected void executeCommand() throws FCAException {
		if(BrowserUtil.isInternetExplorerRunning()){
			feebackWindow.showPopupDialog(Messages.getString("message.close.iexplorer"));
			System.exit(0);
		}
		writeToCSV("ie_history.csv", new InternetExplorerHistoryManager().getHistory(getStartDate(), getEndDate()));
	}

	@Override
	public String getCommandName() {
		return Messages.getString("command.ie");
	}
}
