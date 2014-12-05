package br.com.gss.fca.control.command.browsers;

import br.com.gss.fca.Messages;
import br.com.gss.fca.gui.FeedbackDelegate;
import br.com.gss.fca.history.MozillaFirefoxHistoryManager;
import br.com.gss.fca.util.BrowserUtil;

public class FirefoxAnalysisCommand extends BrowserAnalysisCommand {

	public FirefoxAnalysisCommand(FeedbackDelegate feebackWindow) {
		super(feebackWindow);
	}

	@Override
	protected void executeCommand() {
		if(BrowserUtil.isMozillaFirefoxRunning()){
			feebackWindow.showPopupDialog(Messages.getString("message.close.firefox"));
			System.exit(0);
		}
		writeToCSV("firefox_history.csv", new MozillaFirefoxHistoryManager().getHistory(getStartDate(), getEndDate()));
	}
	
	@Override
	public String getCommandName() {
		return Messages.getString("command.firefox");
	}
}
