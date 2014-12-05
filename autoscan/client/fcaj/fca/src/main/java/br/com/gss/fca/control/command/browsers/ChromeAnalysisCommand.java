package br.com.gss.fca.control.command.browsers;

import br.com.gss.fca.Messages;
import br.com.gss.fca.gui.FeedbackDelegate;
import br.com.gss.fca.history.GoogleChromeHistoryManager;
import br.com.gss.fca.util.BrowserUtil;

public class ChromeAnalysisCommand extends BrowserAnalysisCommand {

	public ChromeAnalysisCommand(FeedbackDelegate feebackWindow) {
		super(feebackWindow);
	}

	@Override
	protected void executeCommand() {
		if(BrowserUtil.isGoogleChromeRunning()){
			feebackWindow.showPopupDialog(Messages.getString("message.close.chrome"));
			System.exit(0);
		}
		writeToCSV("chrome_history.csv", new GoogleChromeHistoryManager().getHistory(getStartDate(), getEndDate()));
	}

	@Override
	public String getCommandName() {
		return Messages.getString("command.chrome");
	}
}
